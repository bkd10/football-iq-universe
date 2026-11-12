{{flutter_js}}
{{flutter_build_config}}

// Polices de secours (emojis, symboles, arabe...) servies par notre site,
// jamais par Google : voir scripts/mirror_fallback_fonts.sh (RGPD).
_flutter.loader.load({
  config: {
    fontFallbackBaseUrl: new URL('fonts/gstatic/', document.baseURI).href,
  },
});
