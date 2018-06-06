cordova-plugin-epos2
====================
Cordova plugin for Epson ePOS SDK(v2.6.0) for iOS and Android.

Integrates the Epson ePOS2 SDK for iOS and Android with a
limited set of functions to discover and connect ePOS printers

Check supported device and requirement from official SDK by Epson.
* [iOS](https://download.epson-biz.com/modules/pos/index.php?page=single_soft&cid=5670&scat=58&pcat=52)
* [Android](https://download.epson-biz.com/modules/pos/index.php?page=single_soft&cid=5669&scat=61&pcat=52)

Install
-------

```
cordova plugin add cordova-plugin-epos2
```

API
===

The plugin exposes an interface object to `cordova.epos2` for direct interaction
with the SDK functions. See `www/plugin.js` for details about the available
functions and their arguments.

### Printer Discovery
#### .startDiscover(successCallback, errorCallback)
This will search for supported printers connected to your mobiel device
via Bluetooth or available in local area network (LAN)

```
cordova.epos2.startDiscover(function(deviceInfo) => {
    // success callback with deviceInfo
}).catch(function(error) => {
    // error callback
});
```
#### .stopDiscover(successCallback, errorCallback)
```
cordova.epos2.stopDiscover(function() => {
    // success callback
}, function(error) => {
    // error callback
})
```

### Printer Connection
#### .connectPrinter(ipAddress, successCallback, errorCallback)
```
window.epos2.connectPrinter(ipAddress, function() => {
    // success callback
}, function(error) => {
    // error callback
})
```
#### .disconnectPrinter(successCallback, errorCallback)
```
window.epos2.disconnectPrinter(function() => {
    // success callback
}, function(error) => {
    // error callback
})
```

### Printing
#### .print(stringData, successCallback, errorCallback)
Use '\n' in string data in order to move to next line.

Cut feed is added automatically.
```
window.epos2.print(stringData, function() => {
    // success callback
}, function(error) => {
    // error callback
})
```

Platforms
---------

* iOS 9+
* Android

## License

[MIT License](http://ilee.mit-license.org)
