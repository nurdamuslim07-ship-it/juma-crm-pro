import { createClient } from 'jsr:@supabase/supabase-js@2';
const headers={'Content-Type':'text/html; charset=utf-8','Cache-Control':'no-store','Referrer-Policy':'no-referrer','Content-Security-Policy':"default-src 'none'; style-src 'unsafe-inline'; frame-ancestors 'none'"};
const escape=(value:unknown)=>String(value??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]!));
Deno.serve(async req=>{
 if(req.method!=='GET')return new Response('Method not allowed',{status:405});
 const token=new URL(req.url).searchParams.get('token')??'';
 const missing=()=>new Response('Сілтеме табылмады немесе мерзімі аяқталды',{status:404,headers});
 if(!/^[0-9a-f]{64}$/.test(token))return missing();
 const digest=Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',new TextEncoder().encode(token)))).map(x=>x.toString(16).padStart(2,'0')).join('');
 const db=createClient(Deno.env.get('SUPABASE_URL')!,Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
 const {data:link}=await db.from('order_tracking_links').select('order_id,company_id').eq('token_hash',digest).gt('expires_at',new Date().toISOString()).maybeSingle();if(!link)return missing();
 const {data:company}=await db.from('companies').select('name').eq('id',link.company_id).eq('is_active',true).maybeSingle();if(!company)return missing();
 const {data:order}=await db.from('orders').select('order_number,product_type,journey_stage,planned_completion_date').eq('id',link.order_id).eq('company_id',link.company_id).is('deleted_at',null).maybeSingle();if(!order)return missing();
 const names:Record<string,string>={measurement:'Өлшеу',design:'Жобаны келісу',contract:'Шарт',advance:'Аванс',cutting:'Кесу',edge_banding:'Жиектеу',assembly:'Құрастыру',quality:'Сапаны тексеру',delivery:'Жеткізу',installation:'Орнату',completed:'Аяқталды'};
 const {data:contracts}=await db.from('order_contracts').select('storage_path,created_at').eq('order_id',link.order_id).eq('company_id',link.company_id).eq('status','approved').order('created_at',{ascending:false}).limit(5);
 const documents:string[]=[];
 for(const c of contracts??[]){const {data}=await db.storage.from('order-contracts').createSignedUrl(c.storage_path,300);if(data)documents.push(`<p><a href="${escape(data.signedUrl)}" rel="noreferrer">Шарт PDF · ${escape(c.created_at.slice(0,10))}</a></p>`);}
 return new Response(`<!doctype html><html lang="kk"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Тапсырыс барысы</title><style>body{font:17px system-ui;background:#edf6fa;color:#123947;padding:24px}main{max-width:560px;margin:auto;background:white;border-radius:28px;padding:28px}strong{display:block;background:#d8f3ec;padding:20px;border-radius:16px}a{color:#076b63}small{color:#526570}</style><main><small>${escape(company.name)}</small><h1>Тапсырыс №${escape(order.order_number)}</h1><p>${escape(order.product_type)}</p><strong>${escape(names[order.journey_stage]??order.journey_stage)}</strong><p>Жоспарланған мерзім: ${escape(order.planned_completion_date??'Нақтылануда')}</p>${documents.join('')}<small>Бұл жеке сілтеме. Оны тек сенімді адамдармен бөлісіңіз.</small></main></html>`,{headers});
});
