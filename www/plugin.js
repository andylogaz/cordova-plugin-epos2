
var exec = require('cordova/exec');

var PLUGIN_NAME = 'epos2';

/**
 * Epson EPOS2 Cordova plugin interface
 * 
 * This is the plugin interface exposed to cordova.epos2
 */
var epos2 = {
  /**
   * Start device discovery
   *
   * This will trigger the successCallback function for every
   * device detected to be available for printing. The device info
   * is provided as single argument to the callback function.
   *
   * @param {Function} successCallback
   * @param {Function} errorCallback
   */
  startDiscover: function(successCallback, errorCallback) {
    exec(successCallback, errorCallback, PLUGIN_NAME, 'startDiscover', []);
  },

  /**
   * Stop running device discovery
   *
   * @param {Function} successCallback
   * @param {Function} errorCallback
   */
  stopDiscover: function(successCallback, errorCallback) {
    exec(successCallback, errorCallback, PLUGIN_NAME, 'stopDiscover', []);
  },

  /**
   * Attempt to connect the given printing device
   *
   * Only if `successCallback` is executed, the printer connection has been established
   * and the plugin is ready to sent print commands. If connection fails, the `errorCallback`
   * is called and printing is not possible.
   *
   * @param {Object|String} device Device information as retrieved from discovery or string with device address ('BT:xx:xx:xx:xx:xx' or 'TCP:xx.xx.xx.xx')
   * @param {String}   printerModel The printer series/model (e.g. 'TM-T88VI') as listed by `getSupportedModels()`
   * @param {Function} successCallback
   * @param {Function} errorCallback
   */
  connectPrinter: function(device, printerModel, successCallback, errorCallback) {
    var args = [];
    if (typeof device === 'object' && device.target) {
      args.push(device.target);
    } else {
      args.push(device);
    }
    if (printerModel && typeof printerModel === 'string') {
      args.push(printerModel);
    }
    exec(successCallback, errorCallback, PLUGIN_NAME, 'connectPrinter', args);
  },

  /**
   * Disconnect a previously connected printer
   *
   * @param {Function} successCallback
   * @param {Function} errorCallback
   */
  disconnectPrinter: function(successCallback, errorCallback) {
    exec(successCallback, errorCallback, PLUGIN_NAME, 'disconnectPrinter', []);
  },

  /**
   * Send a print job to the connected printer
   *
   * This command implicitly sends some additional line feeds an a "cut" command
   * after the given text data to complete the job.
   *
   * @param {Array} data List of strings to be printed as text. Use '\n' to feed paper for one line.
   * @param {Function} successCallback
   * @param {Function} errorCallback
   */
  print: function(data, successCallback, errorCallback) {
    exec(successCallback, errorCallback, PLUGIN_NAME, 'print', data);
  },

  /**
   * Get status information about the connected printer
   *
   * Status object will be returned as the single argument to the `successCallback` function.
   *
   * @param {Function} successCallback
   * @param {Function} errorCallback
   */
  getPrinterStatus: function(successCallback, errorCallback) {
    exec(successCallback, errorCallback, PLUGIN_NAME, 'getPrinterStatus', []);
  },

  /**
   * List the device models supported by the driver
   *
   * Will be returned as the single argument to the `successCallback` function.
   *
   * @param {Function} successCallback
   * @param {Function} errorCallback
   */
  getSupportedModels: function(successCallback, errorCallback) {
    exec(successCallback, errorCallback, PLUGIN_NAME, 'getSupportedModels', []);
  }
};

module.exports = epos2;
