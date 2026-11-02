@IsTest
private class UserInfoHandlerTest {

    @IsTest
    static void returnsDetailsForCurrentUser() {
        List<String> result = UserInfoHandler.getUserDetails(new List<String>{ 'me' });
        System.assertEquals(1, result.size());
        System.assert(result[0].contains(UserInfo.getName()));
    }

    @IsTest
    static void returnsOneResultPerInputAndDefaultsToOne() {
        System.assertEquals(2, UserInfoHandler.getUserDetails(new List<String>{ 'a', 'b' }).size());
        System.assertEquals(1, UserInfoHandler.getUserDetails(null).size());
    }
}