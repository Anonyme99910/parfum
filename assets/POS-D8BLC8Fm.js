import{b as mt,r as i,g as I,h as vt,c,o as p,d as s,j as T,e as b,k as x,v as f,l as a,x as X,F as D,m as L,t as u,s as Z,z as bt,B as xt,w as tt,y as $}from"./index-BVtJ6nZH.js";import{f as G,t as o}from"./numbers-BTmV-EI5.js";import{c as F}from"./createLucideIcon-B-fn_2k4.js";import{P as yt}from"./package-_zstJAlQ.js";import{P as ft}from"./plus-C7nIkIpo.js";import{T as gt}from"./trash-2-pxFlHERU.js";import{U as ht}from"./user-plus-JCdLFSCo.js";/**
 * @license lucide-vue-next v0.294.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */const _t=F("MinusIcon",[["path",{d:"M5 12h14",key:"1ays0h"}]]);/**
 * @license lucide-vue-next v0.294.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */const wt=F("ScanIcon",[["path",{d:"M3 7V5a2 2 0 0 1 2-2h2",key:"aa7l1z"}],["path",{d:"M17 3h2a2 2 0 0 1 2 2v2",key:"4qcy5o"}],["path",{d:"M21 17v2a2 2 0 0 1-2 2h-2",key:"6vwrx8"}],["path",{d:"M7 21H5a2 2 0 0 1-2-2v-2",key:"ioqczr"}]]);/**
 * @license lucide-vue-next v0.294.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */const kt=F("SearchIcon",[["circle",{cx:"11",cy:"11",r:"8",key:"4ej97u"}],["path",{d:"m21 21-4.3-4.3",key:"1qie3q"}]]);/**
 * @license lucide-vue-next v0.294.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */const $t=F("ShoppingCartIcon",[["circle",{cx:"8",cy:"21",r:"1",key:"jimo8o"}],["circle",{cx:"19",cy:"21",r:"1",key:"13723u"}],["path",{d:"M2.05 2.05h2l2.66 12.42a2 2 0 0 0 2 1.58h9.78a2 2 0 0 0 1.95-1.57l1.65-7.43H5.12",key:"9zh506"}]]),Ct={class:"grid grid-cols-1 lg:grid-cols-3 gap-6"},zt={class:"lg:col-span-2 space-y-4"},Pt={class:"card"},qt={class:"flex gap-3"},jt={class:"flex-1 relative"},St={class:"grid grid-cols-2 md:grid-cols-3 gap-4"},Mt=["onClick"],Gt={class:"aspect-square bg-gray-100 rounded-lg mb-3 flex items-center justify-center"},Et={class:"font-bold text-gray-900 mb-1 truncate"},Vt={class:"text-sm text-gray-500 mb-2"},Bt={class:"flex items-center justify-between"},Ut={class:"text-lg font-bold text-primary-600"},It={class:"space-y-4"},Tt={class:"card sticky top-24"},Dt={class:"text-xl font-bold mb-4 flex items-center gap-2"},Lt={class:"space-y-3 mb-4 max-h-64 overflow-y-auto"},Ft={key:0,class:"text-center py-8 text-gray-500"},Nt={class:"flex-1"},At={class:"font-medium text-sm"},Ht={class:"text-xs text-gray-500"},Qt={class:"flex items-center gap-2"},Kt=["onClick"],Ot={class:"w-8 text-center font-bold"},Wt=["onClick"],Yt=["onClick"],Rt={class:"mb-4"},Jt={class:"flex gap-2"},Xt=["value"],Zt={class:"border-t pt-4 space-y-2"},te={class:"flex justify-between text-sm"},ee={class:"font-bold"},se={class:"flex justify-between text-sm"},ne={class:"flex justify-between text-sm"},oe={class:"flex justify-between text-lg font-bold border-t pt-2"},ae={class:"text-primary-600"},le={class:"flex justify-between text-sm bg-blue-50 p-2 rounded"},ie=["placeholder"],re={key:0,class:"flex justify-between text-sm text-red-600 font-bold"},de={class:"mt-4"},ue={class:"grid grid-cols-3 gap-2"},ce=["onClick"],pe={class:"mt-4 space-y-2"},me=["disabled"],ve={key:0,class:"fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50"},be={class:"bg-white rounded-xl p-6 w-full max-w-md"},xe={class:"flex gap-3"},ye={class:"bg-white rounded-xl p-6 w-full max-w-md"},fe={class:"flex gap-3"},Pe={__name:"POS",setup(ge){const m=mt(),C=i([]),z=i([]),r=i([]),y=i(""),P=i(""),g=i(0),h=i(0),q=i(null),N=i("cash"),E=i(!1),j=i(!1),_=i(""),H=i(null),w=i({name:"",phone:""}),Q=[{value:"cash",label:"نقدي"},{value:"card",label:"بطاقة"},{value:"transfer",label:"تحويل"}],et=I(()=>y.value?C.value.filter(t=>t.name_ar.includes(y.value)||t.barcode.includes(y.value)):C.value.slice(0,12)),K=I(()=>r.value.reduce((t,e)=>t+e.product.selling_price*e.quantity,0)),S=I(()=>K.value+h.value-g.value),O=I(()=>{const t=q.value||S.value;return Math.max(0,S.value-t)}),st=async()=>{if(y.value.length<2){A();return}try{const t=await $.getProducts({search:y.value});C.value=t.data}catch{m.error("فشل البحث")}},nt=()=>{E.value=!0,_.value="",setTimeout(()=>{var t;(t=H.value)==null||t.focus()},100)},W=async()=>{if(_.value)try{const t=await $.searchByBarcode(_.value);Y(t.data),E.value=!1,_.value=""}catch{m.error("المنتج غير موجود")}},Y=t=>{if(t.stock_quantity===0){m.error("المنتج غير متوفر في المخزون");return}const e=r.value.find(n=>n.product.id===t.id);if(e){if(e.quantity>=t.stock_quantity){m.error("الكمية المطلوبة غير متوفرة");return}e.quantity++}else r.value.push({product:t,quantity:1});m.success("تم إضافة المنتج للسلة")},ot=t=>{if(t.quantity>=t.product.stock_quantity){m.error("الكمية المطلوبة غير متوفرة");return}t.quantity++},at=t=>{t.quantity>1?t.quantity--:R(t)},R=t=>{r.value=r.value.filter(e=>e.product.id!==t.product.id)},lt=()=>{r.value.length!==0&&confirm("هل أنت متأكد من مسح السلة؟")&&(r.value=[],g.value=0,h.value=0)},it=async()=>{try{const t=await $.createCustomer(w.value);m.success("تم إضافة العميل بنجاح"),z.value.push(t.data),P.value=t.data.id,j.value=!1,w.value={name:"",phone:""}}catch{m.error("فشل إضافة العميل")}},rt=async()=>{var e,n,d;if(r.value.length===0)return;const t={customer_id:P.value||null,items:r.value.map(l=>({product_id:l.product.id,quantity:l.quantity,unit_price:l.product.selling_price})),tax:h.value,discount:g.value,paid_amount:q.value||S.value,payment_method:N.value};try{const l=await $.createSale(t),V=o(l.data.invoice_number);m.success(`تم إنشاء الفاتورة ${V}`);const B=[];confirm("هل تريد طباعة الفاتورة؟")&&dt(l.data),(e=l.data.customer)!=null&&e.phone&&confirm("هل تريد مشاركة الفاتورة عبر واتساب؟")&&ut(l.data),r.value=[],g.value=0,h.value=0,q.value=null,P.value="",A()}catch(l){m.error(((d=(n=l.response)==null?void 0:n.data)==null?void 0:d.error)||"فشل إنشاء الفاتورة")}},dt=t=>{var v,M;const e=window.open("","_blank"),n=((v=t.items)==null?void 0:v.map((k,pt)=>{var J;return`<tr style="border-bottom: 1px solid #e5e7eb;">
      <td style="padding: 6px 8px; text-align: center; font-size: 11px; border-left: 1px solid #e5e7eb;">${pt+1}</td>
      <td style="padding: 6px 8px; text-align: right; font-size: 11px; border-left: 1px solid #e5e7eb;">${((J=k.product)==null?void 0:J.name_ar)||""}</td>
      <td style="padding: 6px 8px; text-align: center; font-size: 11px; border-left: 1px solid #e5e7eb;">${o(k.quantity)}</td>
      <td style="padding: 6px 8px; text-align: right; font-size: 11px; border-left: 1px solid #e5e7eb;">${o(k.unit_price)}</td>
      <td style="padding: 6px 8px; text-align: right; font-size: 11px; font-weight: 600;">${o(k.total_price)}</td>
    </tr>`}).join(""))||"",d=t.customer?t.customer.name:"عميل عادي",l=t.customer?o(t.customer.phone):"-",V=((M=Q.find(k=>k.value===t.payment_method))==null?void 0:M.label)||t.payment_method,B=t.payment_status==="paid"?"مدفوع بالكامل":t.payment_status==="partial"?"مدفوع جزئياً":"غير مدفوع",U=`<!DOCTYPE html>
  <html dir="rtl">
    <head>
      <meta charset="UTF-8">
      <title>فاتورة ${o(t.invoice_number)}</title>
      <style>
        @page { size: A4; margin: 12mm 15mm; }
        * { margin: 0; padding: 0; box-sizing: border-box; -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important; }
        body { font-family: Arial, sans-serif; font-size: 11px; line-height: 1.3; color: #000; }
        .header { text-align: center; margin-bottom: 12px; padding-bottom: 8px; border-bottom: 2px solid #000; }
        .header h1 { font-size: 22px; margin-bottom: 2px; }
        .header h2 { font-size: 14px; color: #555; }
        .info-row { display: flex; justify-content: space-between; margin-bottom: 10px; font-size: 10px; }
        .info-box { flex: 1; padding: 6px; border: 1px solid #ddd; }
        .info-box p { margin: 2px 0; }
        table { width: 100%; border-collapse: collapse; margin: 10px 0; font-size: 10px; }
        th { background: #f5f5f5; border: 1px solid #ddd; padding: 5px; text-align: right; font-weight: bold; }
        td { border: 1px solid #ddd; padding: 5px; text-align: right; }
        .totals { width: 50%; float: left; margin-top: 10px; }
        .totals-row { display: flex; justify-content: space-between; padding: 4px 8px; border-bottom: 1px solid #ddd; font-size: 10px; }
        .totals-row.total { font-weight: bold; font-size: 12px; background: #f0f0f0; border: 1px solid #000; margin-top: 5px; }
        .footer { clear: both; margin-top: 15px; padding-top: 8px; border-top: 1px solid #ddd; text-align: center; font-size: 9px; color: #666; }
        @media print { body { margin: 0; padding: 0; } }
      </style>
    </head>
    <body>
      <div class="header">
        <h1>متجر العطور</h1>
        <h2>فاتورة بيع</h2>
      </div>
      
      <div class="info-row">
        <div class="info-box">
          <p><strong>رقم الفاتورة:</strong> ${o(t.invoice_number)}</p>
          <p><strong>التاريخ:</strong> ${o(new Date(t.created_at).toLocaleDateString("en-GB"))}</p>
          <p><strong>الوقت:</strong> ${o(new Date(t.created_at).toLocaleTimeString("en-GB",{hour:"2-digit",minute:"2-digit"}))}</p>
        </div>
        <div class="info-box" style="text-align: right;">
          <p><strong>العميل:</strong> ${d}</p>
          <p><strong>الهاتف:</strong> ${l}</p>
          <p><strong>طريقة الدفع:</strong> ${V}</p>
        </div>
      </div>
      
      <table>
        <thead>
          <tr>
            <th style="width: 30px; text-align: center;">#</th>
            <th>المنتج</th>
            <th style="width: 50px; text-align: center;">الكمية</th>
            <th style="width: 70px;">السعر</th>
            <th style="width: 70px;">الإجمالي</th>
          </tr>
        </thead>
        <tbody>${n}</tbody>
      </table>
      
      <div class="totals">
        <div class="totals-row"><span>المجموع الفرعي:</span><span>${o(t.subtotal)} EGP</span></div>
        <div class="totals-row"><span>الضريبة:</span><span>${o(t.tax)} EGP</span></div>
        <div class="totals-row"><span>الخصم:</span><span>${o(t.discount)} EGP</span></div>
        <div class="totals-row total"><span>الإجمالي:</span><span>${o(t.total)} EGP</span></div>
        <div class="totals-row" style="margin-top: 5px;"><span>المبلغ المدفوع:</span><span>${o(t.paid_amount||t.total)} EGP</span></div>
        ${t.remaining_amount>0?`<div class="totals-row" style="font-weight: bold; color: #d00;"><span>المتبقي:</span><span>${o(t.remaining_amount)} EGP</span></div>`:""}
        <div class="totals-row" style="margin-top: 5px;"><span>حالة الدفع:</span><span style="font-weight: bold;">${B}</span></div>
      </div>
      
      <div class="footer">
        <p>شكراً لتعاملكم معنا - متجر العطور</p>
        <p>جميع الحقوق محفوظة © ${new Date().getFullYear()}</p>
      </div>
    </body>
  </html>`;e.document.write(U),e.document.close(),setTimeout(()=>e.print(),250)},ut=t=>{var U;const e=z.value.find(v=>v.id===t.customer_id);if(!(e!=null&&e.phone))return;const n=((U=t.items)==null?void 0:U.map(v=>{var M;return`• ${(M=v.product)==null?void 0:M.name_ar}: ${o(v.quantity)} × ${o(v.unit_price)} = ${o(v.total_price)} EGP`}).join("\\n"))||"",d=t.payment_status==="paid"?"مدفوع بالكامل ✅":t.payment_status==="partial"?"مدفوع جزئياً ⚠️":"غير مدفوع ❌",l=`🧴 *فاتورة من متجر العطور*\\n\\n📋 رقم الفاتورة: ${o(t.invoice_number)}\\n📅 التاريخ: ${o(new Date(t.created_at).toLocaleDateString("en-GB"))}\\n\\n*المنتجات:*\\n${n}\\n\\n💰 المجموع الفرعي: ${o(t.subtotal)} EGP\\n🏷️ الخصم: ${o(t.discount)} EGP\\n📊 الضريبة: ${o(t.tax)} EGP\\n*💵 الإجمالي: ${o(t.total)} EGP*\\n\\n✅ المدفوع: ${o(t.paid_amount||t.total)} EGP\\n${t.remaining_amount>0?`⚠️ المتبقي: ${o(t.remaining_amount)} EGP\\n`:""}\\n📌 حالة الدفع: ${d}\\n\\nشكراً لتعاملكم معنا 🌹`,B=`https://wa.me/${e.phone.replace(/[^0-9]/g,"")}?text=${encodeURIComponent(l)}`;window.open(B,"_blank")},A=async()=>{try{const t=await $.getProducts();C.value=t.data.data||t.data||[]}catch(t){console.error("Failed to load products:",t),C.value=[]}},ct=async()=>{try{const t=await $.getCustomers();z.value=t.data.data||t.data||[]}catch(t){console.error("Failed to load customers:",t),z.value=[]}};return vt(()=>{A(),ct()}),(t,e)=>(p(),c("div",Ct,[s("div",zt,[s("div",Pt,[s("div",qt,[s("div",jt,[b(s("input",{"onUpdate:modelValue":e[0]||(e[0]=n=>y.value=n),onInput:st,type:"text",placeholder:"ابحث بالاسم أو الباركود...",class:"input pl-10"},null,544),[[f,y.value]]),x(a(kt),{class:"absolute left-3 top-3 text-gray-400",size:20})]),s("button",{onClick:nt,class:"btn btn-primary flex items-center gap-2"},[x(a(wt),{size:20}),e[12]||(e[12]=X(" مسح الباركود ",-1))])])]),s("div",St,[(p(!0),c(D,null,L(et.value,n=>{var d;return p(),c("div",{key:n.id,onClick:l=>Y(n),class:"card hover:shadow-lg cursor-pointer transition-all hover:scale-105"},[s("div",Gt,[x(a(yt),{size:48,class:"text-gray-400"})]),s("h4",Et,u(n.name_ar),1),s("p",Vt,u((d=n.brand)==null?void 0:d.name_ar),1),s("div",Bt,[s("span",Ut,u(a(G)(n.selling_price)),1),s("span",{class:Z(["text-xs badge",n.stock_quantity>0?"badge-success":"badge-danger"])},u(a(o)(n.stock_quantity))+" قطعة ",3)])],8,Mt)}),128))])]),s("div",It,[s("div",Tt,[s("h3",Dt,[x(a($t),{size:24}),e[13]||(e[13]=X(" سلة المشتريات ",-1))]),s("div",Lt,[r.value.length===0?(p(),c("div",Ft," السلة فارغة ")):T("",!0),(p(!0),c(D,null,L(r.value,n=>(p(),c("div",{key:n.product.id,class:"flex items-center gap-3 p-3 bg-gray-50 rounded-lg"},[s("div",Nt,[s("p",At,u(n.product.name_ar),1),s("p",Ht,u(a(G)(n.product.selling_price)),1)]),s("div",Qt,[s("button",{onClick:d=>at(n),class:"w-7 h-7 rounded bg-gray-200 hover:bg-gray-300"},[x(a(_t),{size:16,class:"mx-auto"})],8,Kt),s("span",Ot,u(a(o)(n.quantity)),1),s("button",{onClick:d=>ot(n),class:"w-7 h-7 rounded bg-gray-200 hover:bg-gray-300"},[x(a(ft),{size:16,class:"mx-auto"})],8,Wt)]),s("button",{onClick:d=>R(n),class:"text-red-600 hover:text-red-800"},[x(a(gt),{size:18})],8,Yt)]))),128))]),s("div",Rt,[e[15]||(e[15]=s("label",{class:"block text-sm font-medium mb-2"},"العميل (اختياري)",-1)),s("div",Jt,[b(s("select",{"onUpdate:modelValue":e[1]||(e[1]=n=>P.value=n),class:"input flex-1"},[e[14]||(e[14]=s("option",{value:""},"عميل عادي",-1)),(p(!0),c(D,null,L(z.value,n=>(p(),c("option",{key:n.id,value:n.id},u(n.name)+" - "+u(a(o)(n.phone)),9,Xt))),128))],512),[[bt,P.value]]),s("button",{onClick:e[2]||(e[2]=n=>j.value=!0),class:"btn btn-secondary"},[x(a(ht),{size:18})])])]),s("div",Zt,[s("div",te,[e[16]||(e[16]=s("span",null,"المجموع الفرعي:",-1)),s("span",ee,u(a(G)(K.value)),1)]),s("div",se,[e[17]||(e[17]=s("span",null,"الخصم:",-1)),b(s("input",{"onUpdate:modelValue":e[3]||(e[3]=n=>g.value=n),type:"number",step:"0.01",class:"input w-32 text-left py-1"},null,512),[[f,g.value,void 0,{number:!0}]])]),s("div",ne,[e[18]||(e[18]=s("span",null,"الضريبة:",-1)),b(s("input",{"onUpdate:modelValue":e[4]||(e[4]=n=>h.value=n),type:"number",step:"0.01",class:"input w-32 text-left py-1"},null,512),[[f,h.value,void 0,{number:!0}]])]),s("div",oe,[e[19]||(e[19]=s("span",null,"الإجمالي:",-1)),s("span",ae,u(a(G)(S.value)),1)]),s("div",le,[e[20]||(e[20]=s("span",null,"المبلغ المدفوع:",-1)),b(s("input",{"onUpdate:modelValue":e[5]||(e[5]=n=>q.value=n),type:"number",step:"0.01",placeholder:S.value.toString(),class:"input w-32 text-left py-1"},null,8,ie),[[f,q.value,void 0,{number:!0}]])]),O.value>0?(p(),c("div",re,[e[21]||(e[21]=s("span",null,"المتبقي:",-1)),s("span",null,u(a(G)(O.value)),1)])):T("",!0)]),s("div",de,[e[22]||(e[22]=s("label",{class:"block text-sm font-medium mb-2"},"طريقة الدفع",-1)),s("div",ue,[(p(),c(D,null,L(Q,n=>s("button",{key:n.value,onClick:d=>N.value=n.value,class:Z([N.value===n.value?"bg-primary-600 text-white":"bg-gray-100","py-2 rounded-lg font-medium transition-all"])},u(n.label),11,ce)),64))])]),s("div",pe,[s("button",{onClick:rt,disabled:r.value.length===0,class:"btn btn-success w-full py-3 text-lg"}," إتمام البيع ",8,me),s("button",{onClick:lt,class:"btn btn-secondary w-full"}," مسح السلة ")])])]),E.value?(p(),c("div",ve,[s("div",be,[e[23]||(e[23]=s("h3",{class:"text-2xl font-bold mb-4"},"مسح الباركود",-1)),b(s("input",{ref_key:"barcodeInput",ref:H,"onUpdate:modelValue":e[6]||(e[6]=n=>_.value=n),onKeyup:xt(W,["enter"]),type:"text",placeholder:"امسح أو اكتب الباركود...",class:"input mb-4",autofocus:""},null,544),[[f,_.value]]),s("div",xe,[s("button",{onClick:e[7]||(e[7]=n=>E.value=!1),class:"btn btn-secondary flex-1"},"إلغاء"),s("button",{onClick:W,class:"btn btn-primary flex-1"},"بحث")])])])):T("",!0),j.value?(p(),c("div",{key:1,class:"fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50",onClick:e[11]||(e[11]=tt(n=>j.value=!1,["self"]))},[s("div",ye,[e[27]||(e[27]=s("h3",{class:"text-2xl font-bold mb-4"},"إضافة عميل",-1)),s("form",{onSubmit:tt(it,["prevent"]),class:"space-y-4"},[s("div",null,[e[24]||(e[24]=s("label",{class:"block text-sm font-medium mb-2"},"الاسم *",-1)),b(s("input",{"onUpdate:modelValue":e[8]||(e[8]=n=>w.value.name=n),type:"text",required:"",class:"input"},null,512),[[f,w.value.name]])]),s("div",null,[e[25]||(e[25]=s("label",{class:"block text-sm font-medium mb-2"},"رقم الهاتف *",-1)),b(s("input",{"onUpdate:modelValue":e[9]||(e[9]=n=>w.value.phone=n),type:"tel",required:"",class:"input"},null,512),[[f,w.value.phone]])]),s("div",fe,[s("button",{type:"button",onClick:e[10]||(e[10]=n=>j.value=!1),class:"btn btn-secondary flex-1"},"إلغاء"),e[26]||(e[26]=s("button",{type:"submit",class:"btn btn-primary flex-1"},"حفظ",-1))])],32)])])):T("",!0)]))}};export{Pe as default};
