@isTest
global class AnimalLocatorMock implements HttpCalloutMock {
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"animal":{"eats":"chicken food","id":1,"name":"chicken","says":"cluck cluck"}}');
        response.setStatusCode(200);
        System.debug('res: '+(Map<String, Object>) JSON.deserializeUntyped(response.getBody()));
        return response;
    }
}