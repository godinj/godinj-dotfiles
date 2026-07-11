// Firefox reads this file on startup and applies settings to prefs.js.
// Add intentional about:config overrides here.
//
// Syntax: user_pref("setting.name", value);

// Enable userChrome.css / userContent.css custom stylesheets
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// Keep the new tab page quiet.
user_pref("browser.newtabpage.activity-stream.showSponsored", false);
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);
user_pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);
user_pref("browser.newtabpage.activity-stream.showWeather", false);
