/**
 * ระบบออกคำสั่งเวรยามสายตรวจ สภ.ศรีมหาโพธิ
 * Apps Script Web App ONLINE v15.1 Fast Load
 * Google Sheet เป็นฐานข้อมูลกลาง + IndexedDB เป็น local cache
 */
const SPREADSHEET_ID = '1XzWdv_OYpAO6FIEF1V8tIlsVBLNfO7QPVRzYoo7RT1k';
const ALLOWED_SHEETS = [
  'settings','teamAssignments','seniorAssignments','postAssignments','specialDuty',
  'schedules','replacements','inspectionPoints','inspections','personnel','personnelMovements'
];

function doGet(e) {
  // เปิดหน้า Web App เมื่อเข้าลิงก์ปกติ
  if (!e || !e.parameter || !e.parameter.action) {
    return HtmlService.createHtmlOutputFromFile('index')
      .setTitle('ระบบจัดเวรสายตรวจ - สภ.ศรีมหาโพธิ')
      .addMetaTag('viewport','width=device-width, initial-scale=1');
  }
  // REST compatibility สำหรับระบบ standalone รุ่นก่อน
  try {
    const action = String(e.parameter.action || 'ping');
    if (action === 'ping') return json_(apiPing());
    if (action === 'all') return json_(apiAll());
    throw new Error('Unknown action: ' + action);
  } catch (err) { return json_({ok:false,error:errorText_(err)}); }
}

// ฟังก์ชันเหล่านี้เรียกจากหน้า index.html ผ่าน google.script.run
function apiPing() {
  try {
    const ss=SpreadsheetApp.openById(SPREADSHEET_ID);
    return {ok:true,title:ss.getName(),spreadsheetId:SPREADSHEET_ID,version:'v15.1',updatedAt:new Date().toISOString()};
  } catch(err) { return {ok:false,error:errorText_(err)}; }
}
function apiAll() {
  try {
    const cache=CacheService.getScriptCache();
    const key='srimahapho_all_v15_1';
    const cached=cache.get(key);
    if(cached){
      try{return {ok:true,data:JSON.parse(cached),updatedAt:new Date().toISOString(),cached:true};}catch(_){ }
    }
    const data=readAll_();
    try{cache.put(key,JSON.stringify(data),60);}catch(_){ }
    return {ok:true,data:data,updatedAt:new Date().toISOString(),cached:false};
  } catch(err) { return {ok:false,error:errorText_(err)}; }
}
function apiReplaceAll(data) {
  const lock=LockService.getScriptLock();
  try {
    if (!data || typeof data !== 'object') throw new Error('Missing data payload');
    lock.waitLock(30000);
    const ss=SpreadsheetApp.openById(SPREADSHEET_ID), counts={};
    ALLOWED_SHEETS.forEach(name=>{
      if (!Array.isArray(data[name])) return;
      counts[name]=writeObjects_(ss,name,data[name]);
    });
    try{CacheService.getScriptCache().remove('srimahapho_all_v15_1');}catch(_){ }
    return {ok:true,counts:counts,updatedAt:new Date().toISOString()};
  } catch(err) { return {ok:false,error:errorText_(err)}; }
  finally { try{lock.releaseLock();}catch(_){} }
}

function readAll_() {
  const ss=SpreadsheetApp.openById(SPREADSHEET_ID), out={};
  ALLOWED_SHEETS.forEach(name=>{
    const sh=ss.getSheetByName(name);
    out[name]=sh?sheetToObjects_(sh):[];
  });
  return out;
}
function sheetToObjects_(sh) {
  const values=sh.getDataRange().getValues();
  if(!values.length)return [];
  const headers=values[0].map(v=>String(v||'').trim());
  const tz=Session.getScriptTimeZone()||'Asia/Bangkok', rows=[];
  for(let r=1;r<values.length;r++){
    const raw=values[r];
    if(raw.every(v=>v===''||v===null))continue;
    const obj={};
    headers.forEach((h,c)=>{
      if(!h)return; let v=raw[c];
      if(Object.prototype.toString.call(v)==='[object Date]'&&!isNaN(v))v=Utilities.formatDate(v,tz,'yyyy-MM-dd');
      if(v!==''&&v!==null)obj[h]=v;
    });
    rows.push(obj);
  }
  return rows;
}
function writeObjects_(ss,name,rows) {
  const sh=ss.getSheetByName(name); if(!sh)throw new Error('Missing sheet: '+name);
  const lastCol=sh.getLastColumn(); if(lastCol<1)throw new Error('Missing headers: '+name);
  const headers=sh.getRange(1,1,1,lastCol).getValues()[0].map(v=>String(v||'').trim());
  if(!headers.some(Boolean))throw new Error('Missing headers: '+name);
  const lastRow=sh.getLastRow(); if(lastRow>1)sh.getRange(2,1,lastRow-1,lastCol).clearContent();
  if(!rows.length)return 0;
  const values=rows.map(obj=>headers.map(h=>toCell_(obj?obj[h]:'')));
  sh.getRange(2,1,values.length,lastCol).setValues(values); return values.length;
}
function toCell_(v){if(v===undefined||v===null)return '';if(typeof v==='object')return JSON.stringify(v);return v;}
function errorText_(err){return String(err&&err.message?err.message:err);}
function json_(obj){return ContentService.createTextOutput(JSON.stringify(obj)).setMimeType(ContentService.MimeType.JSON);}
