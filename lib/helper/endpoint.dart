import '../main_common.dart'; // akses environment

final bool isDev = appEnvironment == Environment.dev;

final host = "https://mms.sanymakmurperkasa.com:8443";
// final apiURL = isDev ? "$host/Sandbox_SAPDUMMY/api" : "$host/Sandbox_SAP/api";
// final apiURLWMS = isDev ? "$host/Sandbox_WMSDUMMY/api" : "$host/Sandbox_WMS/api";

final apiURL = isDev ? "$host/Sandbox_SAPDUMMY/api" : "$host/Sandbox_SAP/api";
final hostLocal = "http://192.168.16.13";
final apiURLWMS = isDev ? "$hostLocal/Sandbox_WMS/api" : "$host/Sandbox_WMS/api";


// SAP
final apiLogin= "$apiURL/SAPLogin";
final apiB1= "$apiURL/SAPB1";
final apiUser= "$apiURL/SAPUser"; 
final apiItem= "$apiURL/SAPItem/wms";
final apiItemHeader= "$apiURL/SAPItem/header";
final apiPO= "$apiURL/SAPPO";
final apiPickPack= "$apiURL/SAPPickPack"; 
final apiPickList= "$apiURL/SAPPickList"; 

// WMS
final apiMenuWMS= "$apiURLWMS/wms_menu_akses";
final apiUserWMS= "$apiURLWMS/wms_user";
final apiDeviceWMS= "$apiURLWMS/wms_user/device";
final apiWarehouseWMS= "$apiURLWMS/wms_warehouse";
final apiLoginWMS= "$apiURLWMS/auth/login";
final apiCekUserWMS= "$apiURLWMS/auth/UserWMS";
final apiRefreshLoginWMS= "$apiURLWMS/auth/refresh";
final apiKonfigurasiWMS= "$apiURLWMS/WMSKonfigurasi"; 
final apiBarcodeWMS= "$apiURLWMS/Barcode/QRHtml"; 
final apiFCMToken= "$apiURLWMS/fcm/set"; 
final apiSendFCM= "$apiURLWMS/fcm/sendByUser";

// const host = "https://mms.sanymakmurperkasa.com:8443";
// const apiURL = "$host/Sandbox_SAPDUmmy/api";
// //const apiURL = "$host/Sandbox_SAP/api";
// const apiLogin= "$apiURL/SAPLogin";
// const apiB1= "$apiURL/SAPB1";
// const apiUser= "$apiURL/SAPUser"; 
// const apiItem= "$apiURL/SAPItem/wms";
// const apiItemHeader= "$apiURL/SAPItem/header";
// const apiPO= "$apiURL/SAPPO";
// const apiPickPack= "$apiURL/SAPPickPack"; 


// // const hostWMS = "http://10.35.84.24";
// const hostWMS = "https://mms.sanymakmurperkasa.com:8443";
// //const hostWMS = "http://localhost";
// const apiURLWMS = "$hostWMS/Sandbox_WMSDUMMY/api";
// const apiMenuWMS= "$apiURLWMS/wms_menu_akses";
// const apiUserWMS= "$apiURLWMS/wms_user";
// const apiDeviceWMS= "$apiURLWMS/wms_user/device";
// const apiWarehouseWMS= "$apiURLWMS/wms_warehouse";
// const apiLoginWMS= "$apiURLWMS/auth/login";
// const apiCekUserWMS= "$apiURLWMS/auth/UserWMS";
// const apiRefreshLoginWMS= "$apiURLWMS/auth/refresh";
// const apiKonfigurasiWMS= "$apiURLWMS/WMSKonfigurasi"; 
// const apiBarcodeWMS= "$apiURLWMS/Barcode/QRHtml"; 
 
// const apiFCMToken= "$apiURLWMS/fcm/set"; 
// const apiSendFCM= "$apiURLWMS/fcm/sendByUser"; 