public with sharing class AnimalLocator {
    public static String getAnimalNameById(Integer Id) {
        Http Http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://th-apex-http-callout.herokuapp.com/animals/' + String.valueOf(Id));
        req.setMethod('GET');
        HttpResponse res = http.send(req);
        System.debug(res);

        String animalName;
        if (res.getStatusCode() == 200) {
            Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            Map<String, Object> animal = (Map<String, Object>) results.get('animal');
            animalName = (String) animal.get('name');
            System.debug(animalName);
        }
        return animalName;
    }
}