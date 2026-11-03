@IsTest
private class ZipCodeNameTest {

    private class Mock implements HttpCalloutMock {
        Integer statusCode;
        String body;

        Mock(Integer statusCode, String body) {
            this.statusCode = statusCode;
            this.body = body;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody(body);
            return res;
        }
    }

    @IsTest
    static void getCityForZipCode_validResults_returnsCityPerZip() {
        Test.setMock(HttpCalloutMock.class, new Mock(200,
            '{"results":{"90210":[{"city":"Beverly Hills"}],"10001":[{"city":"New York"}]}}'));
        Test.startTest();
        List<String> cities = ZipCodeName.getCityForZipCode(new List<Integer>{ 90210, 10001 });
        Test.stopTest();
        System.assertEquals(new List<String>{ 'Beverly Hills', 'New York' }, cities);
    }

    @IsTest
    static void getCityForZipCode_unknownOrMalformedData_returnsNotFound() {
        Test.setMock(HttpCalloutMock.class, new Mock(200,
            '{"results":{"11111":[],"22222":["x"],"33333":[{"city":""}]}}'));
        Test.startTest();
        List<String> cities = ZipCodeName.getCityForZipCode(new List<Integer>{ 11111, 22222, 33333, 44444 });
        Test.stopTest();
        System.assertEquals(new List<String>{ 'City not found', 'City not found', 'City not found', 'City not found' }, cities);
    }

    @IsTest
    static void getCityForZipCode_missingResultsOrApiError_returnsNotFound() {
        Test.setMock(HttpCalloutMock.class, new Mock(200, '{"query":{}}'));
        System.assertEquals(new List<String>{ 'City not found' }, ZipCodeName.getCityForZipCode(new List<Integer>{ 90210 }));

        Test.setMock(HttpCalloutMock.class, new Mock(401, '{"message":"bad key"}'));
        System.assertEquals(new List<String>{ 'City not found' }, ZipCodeName.getCityForZipCode(new List<Integer>{ 90210 }));
    }

    @IsTest
    static void getCityForZipCode_emptyInput_returnsEmptyList() {
        System.assertEquals(0, ZipCodeName.getCityForZipCode(null).size());
        System.assertEquals(0, ZipCodeName.getCityForZipCode(new List<Integer>()).size());
    }
}