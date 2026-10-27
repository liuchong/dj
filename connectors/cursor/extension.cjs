// Native extension-host glue; all control logic is compiled from Eliscript.
exports.activate = async (context) => {
  const { activateCursorControl } = require('./control.cjs');
  return activateCursorControl(require('vscode'), context);
};
