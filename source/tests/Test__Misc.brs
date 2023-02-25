function TestSuite__Misc() as object

    ' Inherite test suite from BaseTestSuite
    this = BaseTestSuite()

    ' Test suite name for log statistics
    this.Name = "MiscTestSuite"

    this.SetUp = MiscTestSuite__SetUp
    this.TearDown = MiscTestSuite__TearDown

    ' Add tests to suite's tests collection
    this.addTest("IsValid() true", TestCase__Misc_IsValid_True)
    this.addTest("IsValid() false", TestCase__Misc_IsValid_False)
    this.addTest("RoundNumber() Floor", TestCase__Misc_RoundNumber_Floor)
    this.addTest("RoundNumber() Ceiling", TestCase__Misc_RoundNumber_Ceiling)

    return this
end function

'----------------------------------------------------------------
' This function called immediately before running tests of current suite.
'----------------------------------------------------------------
sub MiscTestSuite__SetUp()
end sub

'----------------------------------------------------------------
' This function called immediately after running tests of current suite.
'----------------------------------------------------------------
sub MiscTestSuite__TearDown()
end sub

'----------------------------------------------------------------
' Check if isValid() properly identifies valid items
'
' @return An empty string if test is success or error message if not.
'----------------------------------------------------------------
function TestCase__Misc_IsValid_True() as string
    returnResults = ""
    testData = [1, 2, [3, 4], { "key": invalid }, [1, 2, 3], CreateObject("roAppInfo")]

    for each testItem in testData
        returnResults = returnResults + m.AssertTrue(isValid(testItem))
    end for

    return m.AssertEmpty(returnResults)
end function

'----------------------------------------------------------------
' Check if isValid() properly identifies invalid items
'
' @return An empty string if test is success or error message if not.
'----------------------------------------------------------------
function TestCase__Misc_IsValid_False() as string
    returnResults = ""
    testData = [invalid, CreateObject("nothing")]

    for each testItem in testData
        returnResults = m.AssertFalse(isValid(testItem))
    end for

    return m.AssertEmpty(returnResults)
end function

'----------------------------------------------------------------
' Check if roundNumber() properly rounds down
'
' @return An empty string if test is success or error message if not.
'----------------------------------------------------------------
function TestCase__Misc_RoundNumber_Floor() as string
    return m.AssertEqual(roundNumber(9.4), 9)
end function

'----------------------------------------------------------------
' Check if roundNumber() properly rounds up
'
' @return An empty string if test is success or error message if not.
'----------------------------------------------------------------
function TestCase__Misc_RoundNumber_Ceiling() as string
    return m.AssertEqual(roundNumber(9.6), 10)
end function
