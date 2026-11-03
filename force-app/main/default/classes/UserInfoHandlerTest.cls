@IsTest
private class UserInfoHandlerTest {

    @IsTest
    static void getUserDetails_currentUser_returnsUserDetails() {
        List<String> result = UserInfoHandler.getUserDetails(new List<String>{ 'me' });
        System.assertEquals(1, result.size());
        System.assert(result[0].contains(UserInfo.getName()));
    }

    @IsTest
    static void getUserDetails_multipleInputs_returnsOneResultPerInput() {
        System.assertEquals(2, UserInfoHandler.getUserDetails(new List<String>{ 'a', 'b' }).size());
        System.assertEquals(1, UserInfoHandler.getUserDetails(null).size());
    }
}