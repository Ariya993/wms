import '../main_common.dart'; // akses environment

final bool isDev = appEnvironment == Environment.dev;

final host = "https://mms.sanymakmurperkasa.com:8443";

final apiURL = isDev ? "$host/Sandbox_SAPDUMMY/api" : "$host/Sandbox_SAP/api";
final apiURLWMS = isDev ? "$host/Sandbox_WMSDUMMY/api" : "$host/Sandbox_WMS/api";

// final apiURL = isDev ? "$host/Sandbox_SAPDUMMY/api" : "$host/Sandbox_SAP/api";
// final hostLocal = "http://192.168.16.13";
// final apiURLWMS = isDev ? "$hostLocal/Sandbox_WMS/api" : "$host/Sandbox_WMS/api";


// SAP
final apiLogin= "$apiURL/SAPLogin";
final apiB1= "$apiURL/SAPB1";
final apiUser= "$apiURL/SAPUser"; 
final apiItem= "$apiURL/SAPItem/wms";
final apiScanItem= "$apiURL/SAPItem/scan";
final apiItemHeader= "$apiURL/SAPItem/header";
final apiPO= "$apiURL/SAPPO";
final apiGI= "$apiURL/SAPGI";
final apiPickPack= "$apiURL/SAPPickPack"; 
final apiScanPickPack= "$apiURL/SAPPickPack/scan"; 
final apiPickList= "$apiURL/SAPPickList"; 
final apiInventoryIn= "$apiURL/SAPInventoryIn"; 



// WMS
final apiMenuWMS= "$apiURLWMS/wms_menu_akses";
final apiUserWMS= "$apiURLWMS/wms_user";
final apiDeviceWMS= "$apiURLWMS/wms_user/device";
final apiWarehouseWMS= "$apiURLWMS/wms_warehouse";
final apiUserWarehouseWMS= "$apiURLWMS/wms_warehouse/user_warehouse";
final apiLoginWMS= "$apiURLWMS/auth/login";
final apiCekUserWMS= "$apiURLWMS/auth/UserWMS";
final apiRefreshLoginWMS= "$apiURLWMS/auth/refresh";
final apiKonfigurasiWMS= "$apiURLWMS/WMSKonfigurasi"; 
final apiBarcodeWMS= "$apiURLWMS/Barcode/QRHtml"; 
final apiFCMToken= "$apiURLWMS/fcm/set"; 
final apiSendFCM= "$apiURLWMS/fcm/sendByUser";
 final apiTestConn= "$apiURLWMS/auth/protected"; 
 final apiVersionWMS= "$apiURLWMS/WMSKonfigurasi/version"; 