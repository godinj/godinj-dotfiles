// Firefox reads this file on startup and applies settings to prefs.js.
// Add intentional about:config overrides here.
//
// Syntax: user_pref("setting.name", value);

// Enable userChrome.css / userContent.css custom stylesheets
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
