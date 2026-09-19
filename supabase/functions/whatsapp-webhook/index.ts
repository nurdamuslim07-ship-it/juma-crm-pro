import { createClient } from 'jsr:@supabase/supabase-js@2';
Deno.serve(async req=>{
 const url=new URL(req.url),verify=Deno.env.get('WHATSAPP_VERIFY_TOKEN');
 if(req.method==='GET')return verify&&url.searchParams.get('hub.verify_token')===verify&&url.searchParams.get('hub.mode')==='subscribe'?new Response(url.searchParams.get('hub.challenge')):new Response('Forbidden',{status:403});
 if(req.method!=='POST')return new Response('Method not allowed',{status:405});
 const secret=Deno.env.get('META_APP_SECRET');if(!secret)return new Response('Not configured',{status:503});
 const body=await req.text(),signature=req.headers.get('x-hub-signature-256')??'';
 if(!/^sha256=[0-9a-f]{64}$/.test(signature))return new Response('Forbidden',{status:403});
 const key=await crypto.subtle.importKey('raw',new TextEncoder().encode(secret),{name:'HMAC',hash:'SHA-256'},false,['verify']);
 const bytes=Uint8Array.from(signature.slice(7).match(/../g)!,x=>parseInt(x,16));
 if(!await crypto.subtle.verify('HMAC',key,bytes,new TextEncoder().encode(body)))return new Response('Forbidden',{status:403});
 const db=createClient(Deno.env.get('SUPABASE_URL')!,Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
 const company=Deno.env.get('WHATSAPP_COMPANY_ID'),phoneId=Deno.env.get('WHATSAPP_PHONE_NUMBER_ID');
 if(!company||!phoneId)return new Response('Not configured',{status:503});
 try{const payload=JSON.parse(body);
 for(const entry of payload.entry??[])for(const change of entry.changes??[]){
 if(change.value?.metadata?.phone_number_id!==phoneId)continue;
 for(const item of change.value?.statuses??[]){
 const allowed:Record<string,string[]>={sent:['sending','unknown'],delivered:['sending','unknown','sent'],read:['sending','unknown','sent','delivered'],failed:['sending','unknown','sent']};
 if(!allowed[item.status])continue;
 const {error}=await db.from('whatsapp_outbox').update({status:item.status,error_code:item.status==='failed'?String(item.errors?.[0]?.code??'delivery_failed'):null,updated_at:new Date().toISOString()}).eq('company_id',company).eq('provider_id',item.id).in('status',allowed[item.status]);
 if(error)return new Response('Retry',{status:500});
 }
 }return new Response('OK');}catch{return new Response('Bad request',{status:400});}
});
