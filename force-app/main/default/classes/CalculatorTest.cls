@IsTest
private class CalculatorTest {

    @IsTest
    static void constructor_noArgs_createsInstance() {
        System.assertNotEquals(null, new Calculator());
    }
}