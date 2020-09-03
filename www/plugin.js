
var exec = require('cordova/exec');

var PLUGIN_NAME = 'epos2';

/**
 * Wrapper for cordova exec() returning a promise
 * and considering the optional callback arguments
 * 
 * @param {String} cmd Plugin command to execute
 * @param {Array} args Command arguments to send
 * @param {Array} callbackArgs List of arguments with callback functions (the last element is considered the errorCallback, the second-to-last the successCallback)
 * @return {Promise}
 */
function _exec(cmd, args, callbackArgs)
{
  var _successCallback, _errorCallback;
  if (callbackArgs.length > 1 && typeof callbackArgs[callbackArgs.length-1] === 'function') {
    _errorCallback = callbackArgs[callbackArgs.length-1];
  }
  if (callbackArgs.length > 0 && typeof callbackArgs[callbackArgs.length-2] === 'function') {
    _successCallback = callbackArgs[callbackArgs.length-2];
  }

  return new Promise(function(resolve, reject) {
    // call cordova/exec
    exec(
      function(result) {
        if (_successCallback) {
          _successCallback(result);
        }
        resolve(result);
      },
      function(err) {
        if (_errorCallback) {
          _errorCallback(err);
        }
        reject(new Error(err));
      },
      PLUGIN_NAME,
      cmd,
      args
    );
  });
}

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
   * @param {Function} [errorCallback]
   * @return {Promise} resolves when the first device is detected or rejects if operation times out
   */
  startDiscover: function(successCallback, errorCallback) {
    return new Promise(function(resolve, reject) {
      // start timer to reject promise eventually
      var timeout = setTimeout(function() {
        reject(new Error('Error 0x00001: No devices found'));
      }, 20000);

      exec(function(result) {
        clearTimeout(timeout);
        if (typeof successCallback === 'function') {
          successCallback(result);
        }
        resolve(result);
        },
        function(err) {
          clearTimeout(timeout);
          if (typeof errorCallback === 'function') {
            errorCallback(err);
          }
          reject(new Error(err));
        },
        PLUGIN_NAME,
        'startDiscover',
        []
      );
    });
  },

  /**
   * Stop running device discovery
   *
   * @param {Function} [successCallback]
   * @param {Function} [errorCallback]
   * @return {Promise}
   */
  stopDiscover: function(successCallback, errorCallback) {
    return _exec('stopDiscover', [], arguments);
  },

  /**
   * Attempt to connect the given printing device
   *
   * Only if the promise resolves, the printer connection has been established
   * and the plugin is ready to sent print commands. If connection fails, the
   * promise rejects and printing is not possible.
   *
   * @param {Object|String} device Device information as retrieved from discovery
   *          or string with device address ('BT:xx:xx:xx:xx:xx' or 'TCP:xx.xx.xx.xx')
   * @param {String}   printerModel The printer series/model (e.g. 'TM-T88VI') as listed by `getSupportedModels()`
   * @param {Function} [successCallback]
   * @param {Function} [errorCallback]
   * @return {Promise}
   */
  connectPrinter: function(device, printerModel) {
    var args = [];
    if (typeof device === 'object' && device.target) {
      args.push(device.target);
    } else {
      args.push(device);
    }
    if (printerModel && typeof printerModel === 'string') {
      args.push(printerModel);
    }
    return _exec('connectPrinter', args, arguments);
  },

  /**
   * Disconnect a previously connected printer
   *
   * @param {Function} [successCallback]
   * @param {Function} [errorCallback]
   * @return {Promise}
   */
  disconnectPrinter: function(successCallback, errorCallback) {
    return _exec('disconnectPrinter', [], arguments);
  },

  /**
   * Send a print job to the connected printer
   *
   * This command is limited to print text and implicitly sends some additional
   * line feeds an a "cut" command after the given text data to complete the job.
   *
   * @param {Array} data List of strings to be printed as text. Use '\n' to feed paper for one line.
   * @param {Function} [successCallback]
   * @param {Function} [errorCallback]
   * @return {Promise} resolving on success, rejecting on error
   * @deprecated Use dedicated methods like `printText()` or `printImage()` 
   */
  print: function(data, successCallback, errorCallback) {
    return _exec('printText', [data, 0, 1, 0], [])
      .then(function() {
        return _exec('sendData', [], []);
      })
      .then(function(result) {
        if (typeof successCallback === 'function') {
          successCallback(result);
        }
      })
      .catch(function(err) {
        if (typeof errorCallback === 'function') {
          errorCallback(err);
        }
        throw err;
      });
  },

  /**
   * Send text to the connected printer
   *
   * Can be called multiple times for additional text lines.
   * Set `terminate` to True in order to complete the print job.
   *
   * @param {String|Array} data List of strings to be printed as text. Use '\n' to feed paper for one line.
   * @param {Number} [textFont=0] Select font: 0 = Font A, 1 = Font B, 2 = Font C, 3 = Font D, 4 = Font E
   * @param {Number} [textSize=1] Define text size (1..8)
   * @param {Number} [textAlign=0] Define text alignment: 0 = left, 1 = center, 2 = right
   * @param {Number} [textReverse=0] Define text reverse: 0 = disabled, 1 = enabled
   * @param {Number} [textUnderline=0] Define text underline: 0 = disabled, 1 = enabled
   * @param {Number} [textEmphasis=0] Define text bold: 0 = disabled, 1 = enabled
   * @param {Number} [textColour=1] Define text colour: 0 = no print, 1 = default, 2 = second colour, 3 = third colour, 4 = fourth colour
   * @param {Number} [doubleWidth=0] Define doubleWidth Printing: 0 = disabled, 1 = enabled
   * @param {Number} [doubleHeight=0] Define doubleHeight Printing: 0 = disabled, 1 = enabled
   * @param {Boolean} [terminate=false] Send additional line feeds an a "cut" command to complete the print
   * @param {Function} [successCallback]
   * @param {Function} [errorCallback]
   * @return {Promise} resolving on success, rejecting on error
   */
  printText: function(data, textFont, textSize, doubleWidth, doubleHeight, textAlign, textReverse, textUnderline, textEmphasis, textColour, terminate, successCallback, errorCallback) {
    // convert data argument to array
    if (!Array.isArray(data)) {
      data = [String(data)];
    }
    let textWidth = textSize || 1
    let textHeight = textSize || 1
    if(doubleWidth) textWidth *= 2
    if(doubleHeight) textHeight *= 2

    return _exec('printText', [data, textFont || 0, textWidth, textHeight, textAlign || 0, textReverse || 0, textUnderline || 0, textEmphasis || 0, textColour || 1], arguments)
      .then(function(result) {
        return terminate ? _exec('sendData', [], []) : result;
      })
      .then(function(result) {
        if (typeof successCallback === 'function') {
          successCallback(result);
        }
      })
      .catch(function(err) {
        if (typeof errorCallback === 'function') {
          errorCallback(err);
        }
        throw err;
      });
  },
  /**
   * 
   * @param {Function} successCallback 
   * @param {Function} errorCallback 
   */
  addFeed: function(successCallback, errorCallback) {
    return _exec('addFeed', [], arguments)
    .then(function(result) {
      if (typeof successCallback === 'function') {
        successCallback(result);
      }
    })
    .catch(function(err) {
      if (typeof errorCallback === 'function') {
        errorCallback(err);
      }
      throw err;
    });
  },

  /**
   * 
   * @param {Function} successCallback 
   * @param {Function} errorCallback 
   */
  addCut: function(successCallback, errorCallback) {
    return _exec('addCut', [], arguments)
    .then(function(result) {
      if (typeof successCallback === 'function') {
        successCallback(result);
      }
    })
    .catch(function(err) {
      if (typeof errorCallback === 'function') {
        errorCallback(err);
      }
      throw err;
    });
  },

  /**
   * 
   * @param {Number} [pin = 2] Define the pin to fire (2 / 5)
   * @param {Number} [time = 100] Define millisecond time for signal (100/200/300/400/500)
   * @param {Function} successCallback 
   * @param {Function} errorCallback 
   */
  kickDraw: function(pin, time, successCallback, errorCallback) {
    if(pin !== 5) pin = 2
    if(!time) time = 100
    time = 100 * Math.Ceil(time/100)
    if(time < 100) time = 100
    if(time > 500) time = 500

    return _exec('kickDraw', [pin, time], arguments)
    .then(function(result) {
      if (typeof successCallback === 'function') {
        successCallback(result);
      }
    })
    .catch(function(err) {
      if (typeof errorCallback === 'function') {
        errorCallback(err);
      }
      throw err;
    });
  },
  
  addBarcode: function(successCallback, errorCallback) {
    errorCallback("Not yet implemented")
  },
  
  addSymbol: function(successCallback, errorCallback) {
    errorCallback("Not yet implemented")
  },

  /**
   * Send image data to the connected printer
   *
   * Set `terminate` to True in order to complete the print job.
   *
   * @param {String} data Image source as data-url (e.g. data:image/png;base64,xxxxx)
   * @param {Number} [printMode=0] Specifies the color mode: 0 = Monochrome, 1 = Multi-gradation (16 scales), 2 = Monochrome, double density
   * @param {Number} [halfTone=0] Halftone processing method: 0 = Dithering, 1 = Error diffusion, 2 = Threshold
   * @param {Boolean} [terminate=false] Send additional line feeds an a "cut" command to complete the print
   * @param {Function} [successCallback]
   * @param {Function} [errorCallback]
   * @return {Promise} resolving on success, rejecting on error
   */
  printImage: function(data, printMode, halfTone, terminate, successCallback, errorCallback) {
    return _exec('printImage', [data, printMode || 0, halfTone || 0], arguments)
      .then(function(result) {
        return terminate ? _exec('sendData', [], []) : result;
      })
      .then(function(result) {
        if (typeof successCallback === 'function') {
          successCallback(result);
        }
      })
      .catch(function(err) {
        if (typeof errorCallback === 'function') {
          errorCallback(err);
        }
        throw err;
      });
  },

  /**
   * Get status information about the connected printer
   *
   * Status object will be returned as the single argument to the `successCallback` function if provided.
   *
   * @param {Function} [successCallback]
   * @param {Function} [errorCallback]
   * @return {Promise} resolving with the printer status information
   */
  getPrinterStatus: function(successCallback, errorCallback) {
    return _exec('getPrinterStatus', [], arguments);
  },

  /**
   * List the device models supported by the driver
   *
   * Will be returned as the single argument to the `successCallback` function if provided.
   *
   * @param {Function} [successCallback]
   * @param {Function} [errorCallback]
   * @return {Promise} resolving with the list of model names
   */
  getSupportedModels: function(successCallback, errorCallback) {
    return _exec('getSupportedModels', [], arguments);
  }
};

module.exports = epos2;
