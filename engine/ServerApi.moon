J = js.global
_G.ServerConnection = newType {
	init: (@url = "/game") =>
	login: () =>
		J.jQuery\ajax jsObject {
			type: "POST",
			url: @url,
			dataType: "json",
			contentType: "application/json",
			data: jsObject {hithere: "HIETHERE"},
			success: () => print @data 
		}
}	
