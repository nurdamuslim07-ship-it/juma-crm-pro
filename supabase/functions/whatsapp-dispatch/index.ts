import { createClient } from 'jsr:@supabase/supabase-js@2';
// Server-only integration, deliberately inactive until all credentials/templates are configured.
const json = (data: unknown, status=200) => Response.json(data,{status});
Deno.serve(async req => {
 const secret=Deno.env.get('WHATSAPP_WORKER_SECRET');
 if(req.method!=='POST'||!secret||req.headers.get('Authorization')!==`Bearer ${secret}`) return json({error:'Unauthorized'},401);
 const company=Deno.env.get('WHATSAPP_COMPANY_ID'),phoneId=Deno.env.get('WHATSAPP_PHONE_NUMBER_ID'),token=Deno.env.get('WHATSAPP_ACCESS_TOKEN'),version=Deno.env.get('META_GRAPH_VERSION'),stageTemplate=Deno.env.get('WHATSAPP_STAGE_TEMPLATE'),contractTemplate=Deno.env.get('WHATSAPP_CONTRACT_TEMPLATE'),language=Deno.env.get('WHATSAPP_TEMPLATE_LANGUAGE');
 if(!company||!phoneId||!token||!version||!stageTemplate||!contractTemplate||!language) return json({error:'Integration not configured'},503);
 if(!/^v\d+\.\d+$/.test(version)||!/^\d+$/.test(phoneId))return json({error:'Invalid integration configuration'},503);
 const db=createClient(Deno.env.get('SUPABASE_URL')!,Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
 const {data,error}=await db.rpc('claim_whatsapp_message',{p_company_id:company});
 if(error)return json({error:'Queue unavailable'},500);
 const message=data?.[0];if(!message)return json({processed:0});
 let requestStarted=false;
 try {
  const {data:client,error:clientError}=await db.from('clients').select('phone').eq('id',message.client_id).eq('company_id',company).single();
  if(clientError)throw Error('client_unavailable');
  const {data:consent}=await db.from('client_whatsapp_consent').select('enabled').eq('client_id',message.client_id).eq('company_id',company).single();
  if(!consent?.enabled){await db.from('whatsapp_outbox').update({status:'skipped',error_code:'consent_revoked',updated_at:new Date().toISOString()}).eq('id',message.id);return json({processed:0});}
  let to=client.phone.replace(/\D/g,'');if(to.length===11&&to.startsWith('8'))to='7'+to.slice(1);
  if(!/^[1-9]\d{7,14}$/.test(to))throw Error('invalid_phone');
  const components:unknown[]=[];
  const names:Record<string,string>=language.startsWith('ru')?{measurement:'Замер',design:'Согласование проекта',contract:'Договор',advance:'Аванс',cutting:'Раскрой',edge_banding:'Кромкование',assembly:'Сборка',quality:'Контроль качества',delivery:'Доставка',installation:'Монтаж',completed:'Завершён'}:{measurement:'Өлшеу',design:'Жобаны келісу',contract:'Шарт',advance:'Аванс',cutting:'Кесу',edge_banding:'Жиектеу',assembly:'Құрастыру',quality:'Сапаны тексеру',delivery:'Жеткізу',installation:'Орнату',completed:'Аяқталды'};
  if(message.kind==='contract'){
   const path=message.payload.storage_path;
   if(typeof path!=='string'||!path.startsWith(company+'/'))throw Error('invalid_document');
   const {data:signed,error}=await db.storage.from('order-contracts').createSignedUrl(path,3600);
   if(error||!signed)throw Error('document_unavailable');
   components.push({type:'header',parameters:[{type:'document',document:{link:signed.signedUrl,filename:'JUMA-contract.pdf'}}]});
  }
  const texts=message.kind==='contract'?[message.payload.order_number]:[message.payload.client_name,message.payload.order_number,names[message.payload.stage]??message.payload.stage];
  components.push({type:'body',parameters:texts.map(text=>({type:'text',text:String(text??'')}))});
  requestStarted=true;
  const response=await fetch(`https://graph.facebook.com/${version}/${phoneId}/messages`,{method:'POST',headers:{Authorization:`Bearer ${token}`,'Content-Type':'application/json'},body:JSON.stringify({messaging_product:'whatsapp',to,type:'template',template:{name:message.kind==='contract'?contractTemplate:stageTemplate,language:{code:language},components}}),signal:AbortSignal.timeout(20000)});
  const result=await response.json();
  const providerId=result.messages?.[0]?.id;
  const status=response.ok&&providerId?'sent':response.status>=500?'unknown':'failed';
  const {error:updateError}=await db.from('whatsapp_outbox').update({status,provider_id:providerId??null,error_code:response.ok?null:String(result.error?.code??response.status),updated_at:new Date().toISOString()}).eq('id',message.id).eq('status','sending');
  if(updateError)return json({error:'Delivery reconciliation required'},500);
  return json({processed:1,status});
 }catch(e){
  // Never blindly retry an ambiguous POST: Meta may have accepted it already.
  const status=requestStarted?'unknown':'failed';
  await db.from('whatsapp_outbox').update({status,error_code:requestStarted?'delivery_unknown':(e instanceof Error?e.message:'preflight_failed'),updated_at:new Date().toISOString()}).eq('id',message.id).eq('status','sending');
  return json({processed:1,status});
 }
});
