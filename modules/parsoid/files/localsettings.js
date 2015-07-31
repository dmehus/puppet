"use strict";

exports.setup = function( parsoidConfig ) {
	// wiki end points
	parsoidConfig.setInterwiki( 'metawiki', 'https://meta.miraheze.org/w/api.php' );

	// Enable debug mode (prints extra debugging messages)
	parsoidConfig.debug = false;

	parsoidConfig.usePHPPreProcessor = true;

	// Use selective serialization (default false)
	parsoidConfig.useSelser = true;
};
