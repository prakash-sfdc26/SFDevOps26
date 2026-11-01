@IsTest
private class CalculatorTest {

    @IsTest
    static void canBeInstantiated() {
        System.assertNotEquals(null, new Calculator());
    }
}