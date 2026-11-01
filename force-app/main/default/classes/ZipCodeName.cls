public with sharing class ZipCodeName {

    private static final String ENDPOINT = 'https://api.zipcodestack.com/v1/search';
    // TODO: move to a Named Credential (callout:...) so the key is not stored in source
    private static final String API_KEY = 'YOUR_API_KEY';
    private static final String NOT_FOUND = 'City not found';

    @InvocableMethod(callout=true
                     description='This Action Find the Name of the City based on the Zipcode given to it, for example when the user ask find the name of the City whose zip code is 90210 then it returns the city name')
    public static List<String> getCityForZipCode(List<Integer> zipCode) {
        if (zipCode == null || zipCode.isEmpty()) {
            return new List<String>();
        }

        // The API accepts comma separated codes, so one callout serves the whole batch
        List<String> codes = new List<String>();
        for (Integer zip : zipCode) {
            codes.add(String.valueOf(zip));
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint(ENDPOINT + '?codes=' + EncodingUtil.urlEncode(String.join(codes, ','), 'UTF-8') + '&country=us');
        req.setMethod('GET');
        req.setHeader('apikey', API_KEY);

        Map<String, Object> results = new Map<String, Object>();
        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() == 200) {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            if (responseMap.get('results') instanceof Map<String, Object>) {
                results = (Map<String, Object>) responseMap.get('results');
            }
        }

        List<String> cities = new List<String>();
        for (String code : codes) {
            cities.add(extractCity(results.get(code)));
        }
        return cities;
    }

    private static String extractCity(Object zipData) {
        if (zipData instanceof List<Object> && !((List<Object>) zipData).isEmpty()) {
            Object first = ((List<Object>) zipData)[0];
            if (first instanceof Map<String, Object>) {
                String city = (String) ((Map<String, Object>) first).get('city');
                if (String.isNotBlank(city)) {
                    return city;
                }
            }
        }
        return NOT_FOUND;
    }
}