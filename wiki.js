$(document).ready(function() {
	$('#goto').bind('keypress', function(e) {
		var code = (e.keyCode ? e.keyCode : e.which);
		if(code == 13) { // Enter
			document.location = '/' + this.value.toLowerCase();
		}
	});
});
