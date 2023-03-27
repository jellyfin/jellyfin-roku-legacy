'*****************************************************************
'* Roku Unit Testing Framework
'* Automating test suites for Roku channels.
'*
'* Build Version: 2.1.1
'* Build Date: 05/06/2019
'*
'* Public Documentation is avaliable on GitHub:
'* 		https://github.com/rokudev/unit-testing-framework
'*
'*****************************************************************
'*****************************************************************
'* Copyright Roku 2011-2019
'* All Rights Reserved
'*****************************************************************

' Functions in this file:

'     BaseTestSuite
'     BTS__AddTest
'     BTS__CreateTest
'     BTS__Fail
'     BTS__AssertFalse
'     BTS__AssertTrue
'     BTS__AssertEqual
'     BTS__AssertNotEqual
'     BTS__AssertInvalid
'     BTS__AssertNotInvalid
'     BTS__AssertAAHasKey
'     BTS__AssertAANotHasKey
'     BTS__AssertAAHasKeys
'     BTS__AssertAANotHasKeys
'     BTS__AssertArrayContains
'     BTS__AssertArrayNotContains
'     BTS__AssertArrayContainsSubset
'     BTS__AssertArrayNotContainsSubset
'     BTS__AssertArrayCount
'     BTS__AssertArrayNotCount
'     BTS__AssertEmpty
'     BTS__AssertNotEmpty

' ----------------------------------------------------------------
' Main function. Create BaseTestSuite object.

' @return A BaseTestSuite object.
' ----------------------------------------------------------------
function BaseTestSuite()
    this = {}
    this.Name = "BaseTestSuite"
    this.SKIP_TEST_MESSAGE_PREFIX = "SKIP_TEST_MESSAGE_PREFIX__"
    ' Test Cases methods
    this.testCases = []
    this.IS_NEW_APPROACH = false
    this.addTest = BTS__AddTest
    this.createTest = BTS__CreateTest
    this.StorePerformanceData = BTS__StorePerformanceData

    ' Assertion methods which determine test failure or skipping
    this.skip = BTS__Skip
    this.fail = BTS__Fail
    this.assertFalse = BTS__AssertFalse
    this.assertTrue = BTS__AssertTrue
    this.assertEqual = BTS__AssertEqual
    this.assertNotEqual = BTS__AssertNotEqual
    this.assertInvalid = BTS__AssertInvalid
    this.assertNotInvalid = BTS__AssertNotInvalid
    this.assertAAHasKey = BTS__AssertAAHasKey
    this.assertAANotHasKey = BTS__AssertAANotHasKey
    this.assertAAHasKeys = BTS__AssertAAHasKeys
    this.assertAANotHasKeys = BTS__AssertAANotHasKeys
    this.assertArrayContains = BTS__AssertArrayContains
    this.assertArrayNotContains = BTS__AssertArrayNotContains
    this.assertArrayContainsSubset = BTS__AssertArrayContainsSubset
    this.assertArrayNotContainsSubset = BTS__AssertArrayNotContainsSubset
    this.assertArrayCount = BTS__AssertArrayCount
    this.assertArrayNotCount = BTS__AssertArrayNotCount
    this.assertEmpty = BTS__AssertEmpty
    this.assertNotEmpty = BTS__AssertNotEmpty

    ' Type Comparison Functionality
    this.eqValues = TF_Utils__EqValues
    this.eqAssocArrays = TF_Utils__EqAssocArray
    this.eqArrays = TF_Utils__EqArray
    this.baseComparator = TF_Utils__BaseComparator

    return this
end function

' ----------------------------------------------------------------
' Add a test to a suite's test cases array.

' @param name (string) A test name.
' @param func (object) A pointer to test function.
' @param setup (object) A pointer to setup function.
' @param teardown (object) A pointer to teardown function.
' @param arg (dynamic) A test function arguments.
' @param hasArgs (boolean) True if test function has parameters.
' @param skip (boolean) Skip test run.
' ----------------------------------------------------------------
sub BTS__AddTest(name as string, func as object, setup = invalid as object, teardown = invalid as object, arg = invalid as dynamic, hasArgs = false as boolean, skip = false as boolean)
    m.testCases.Push(m.createTest(name, func, setup, teardown, arg, hasArgs, skip))
end sub

' ----------------------------------------------------------------
' Create a test object.

' @param name (string) A test name.
' @param func (object) A pointer to test function.
' @param setup (object) A pointer to setup function.
' @param teardown (object) A pointer to teardown function.
' @param arg (dynamic) A test function arguments.
' @param hasArgs (boolean) True if test function has parameters.
' @param skip (boolean) Skip test run.
'
' @return TestCase object.
' ----------------------------------------------------------------
function BTS__CreateTest(name as string, func as object, setup = invalid as object, teardown = invalid as object, arg = invalid as dynamic, hasArgs = false as boolean, skip = false as boolean) as object
    return {
        Name: name
        Func: func
        SetUp: setup
        TearDown: teardown

        perfData: {}

        hasArguments: hasArgs
        arg: arg

        skip: skip
    }
end function

'----------------------------------------------------------------
' Store performance data to current test instance.
'
' @param name (string) A property name.
' @param value (Object) A value of data.
'----------------------------------------------------------------
sub BTS__StorePerformanceData(name as string, value as object)
    timestamp = StrI(CreateObject("roDateTime").AsSeconds())
    m.testInstance.perfData.Append({
        name: {
            "value": value
            "timestamp": timestamp
        }
    })
    ' print performance data to console
    ? "PERF_DATA: " + m.testInstance.Name + ": " + timestamp + ": " + name + "|" + TF_Utils__AsString(value)
end sub

' ----------------------------------------------------------------
' Assertion methods which determine test failure or skipping
' ----------------------------------------------------------------

' ----------------------------------------------------------------
' Should be used to skip test cases. To skip test you must return the result of this method invocation.

' @param message (string) Optional skip message.
' Default value: "".

' @return A skip message, with a specific prefix added, in order to runner know that this test should be skipped.
' ----------------------------------------------------------------
function BTS__Skip(message = "" as string) as string
    ' add prefix so we know that this test is skipped, but not failed
    return m.SKIP_TEST_MESSAGE_PREFIX + message
end function

' ----------------------------------------------------------------
' Fail immediately, with the given message

' @param msg (string) An error message.
' Default value: "Error".

' @return An error message.
' ----------------------------------------------------------------
function BTS__Fail(msg = "Error" as string) as string
    return msg
end function

' ----------------------------------------------------------------
' Fail the test if the expression is true.

' @param expr (dynamic) An expression to evaluate.
' @param msg (string) An error message.
' Default value: "Expression evaluates to true"

' @return An error message.
' ----------------------------------------------------------------
function BTS__AssertFalse(expr as dynamic, msg = "Expression evaluates to true" as string) as string
    if not TF_Utils__IsBoolean(expr) or expr
        return BTS__Fail(msg)
    end if
    return ""
end function

' ----------------------------------------------------------------
' Fail the test unless the expression is true.

' @param expr (dynamic) An expression to evaluate.
' @param msg (string) An error message.
' Default value: "Expression evaluates to false"

' @return An error message.
' ----------------------------------------------------------------
function BTS__AssertTrue(expr as dynamic, msg = "Expression evaluates to false" as string) as string
    if not TF_Utils__IsBoolean(expr) or not expr then
        return msg
    end if
    return ""
end function

' ----------------------------------------------------------------
' Fail if the two objects are unequal as determined by the '<>' operator.

' @param first (dynamic) A first object to compare.
' @param second (dynamic) A second object to compare.
' @param msg (string) An error message.
' Default value: ""

' @return An error message.
' ----------------------------------------------------------------
function BTS__AssertEqual(first as dynamic, second as dynamic, msg = "" as string) as string
    if not TF_Utils__EqValues(first, second)
        if msg = ""
            first_as_string = TF_Utils__AsString(first)
            second_as_string = TF_Utils__AsString(second)
            msg = first_as_string + " != " + second_as_string
        end if
        return msg
    end if
    return ""
end function

' ----------------------------------------------------------------
' Fail if the two objects are equal as determined by the '=' operator.

' @param first (dynamic) A first object to compare.
' @param second (dynamic) A second object to compare.
' @param msg (string) An error message.
' Default value: ""

' @return An error message.
' ----------------------------------------------------------------
function BTS__AssertNotEqual(first as dynamic, second as dynamic, msg = "" as string) as string
    if TF_Utils__EqValues(first, second)
        if msg = ""
            first_as_string = TF_Utils__AsString(first)
            second_as_string = TF_Utils__AsString(second)
            msg = first_as_string + " == " + second_as_string
        end if
        return msg
    end if
    return ""
end function

' ----------------------------------------------------------------
' Fail if the value is not invalid.

' @param value (dynamic) A value to check.
' @param msg (string) An error message.
' Default value: ""

' @return An error message.
' ----------------------------------------------------------------
function BTS__AssertInvalid(value as dynamic, msg = "" as string) as string
    if TF_Utils__IsValid(value)
        if msg = ""
            expr_as_string = TF_Utils__AsString(value)
            msg = expr_as_string + " <> Invalid"
        end if
        return msg
    end if
    return ""
end function

' ----------------------------------------------------------------
' Fail if the value is invalid.

' @param value (dynamic) A value to check.
' @param msg (string) An error message.
' Default value: ""

' @return An error message.
' ----------------------------------------------------------------
function BTS__AssertNotInvalid(value as dynamic, msg = "" as string) as string
    if not TF_Utils__IsValid(value)
        if msg = ""
            if LCase(Type(value)) = "<uninitialized>" then value = invalid
            expr_as_string = TF_Utils__AsString(value)
            msg = expr_as_string + " = Invalid"
        end if
        return msg
    end if
    return ""
end function

' ----------------------------------------------------------------
' Fail if the array doesn't have the key.

' @param array (dynamic) A target array.
' @param key (string) A key name.
' @param msg (string) An error message.
' Default value: ""

' @return An error message.
' ----------------------------------------------------------------
function BTS__AssertAAHasKey(array as dynamic, key as dynamic, msg = "" as string) as string
    if not TF_Utils__IsString(key)
        return "Key value has invalid type."
    end if

    if TF_Utils__IsAssociativeArray(array)
        if not array.DoesExist(key)
            if msg = ""
                msg = "Array doesn't have the '" + key + "' key."
            end if
            return msg
        end if
    else
        msg = "Input value is not an Associative Array."
        return msg
    end if

    return ""
end function

' ----------------------------------------------------------------
' Fail if the array has the key.

' @param array (dynamic) A target array.
' @param key (string) A key name.
' @param msg (string) An error message.
' Default value: ""

' @return An error message.
' ----------------------------------------------------------------
function BTS__AssertAANotHasKey(array as dynamic, key as dynamic, msg = "" as string) as string
    if not TF_Utils__IsString(key)
        return "Key value has invalid type."
    end if

    if TF_Utils__IsAssociativeArray(array)
        if array.DoesExist(key)
            if msg = ""
                msg = "Array has the '" + key + "' key."
            end if
            return msg
        end if
    else
        msg = "Input value is not an Associative Array."
        return msg
    end if

    return ""
end function

' ----------------------------------------------------------------
' Fail if the array doesn't have the keys list.

' @param array (dynamic) A target associative array.
' @param keys (object) A key names array.
' @param msg (string) An error message.
' Default value: ""

' @return An error message.
' ----------------------------------------------------------------
function BTS__AssertAAHasKeys(array as dynamic, keys as object, msg = "" as string) as string
    if not TF_Utils__IsAssociativeArray(array)
        return "Input value is not an Associative Array."
    end if

    if not TF_Utils__IsArray(keys) or keys.Count() = 0
        return "Keys value is not an Array or is empty."
    end if

    if TF_Utils__IsAssociativeArray(array) and TF_Utils__IsArray(keys)
        for each key in keys
            if not TF_Utils__IsString(key)
                return "Key value has invalid type."
            end if

            if not array.DoesExist(key)
                if msg = ""
                    msg = "Array doesn't have the '" + key + "' key."
                end if

                return msg
            end if
        end for
    else
        msg = "Input value is not an Associative Array."
        return msg
    end if

    return ""
end function

' ----------------------------------------------------------------
' Fail if the array has the keys list.

' @param array (dynamic) A target associative array.
' @param keys (object) A key names array.
' @param msg (string) An error message.
' Default value: ""

' @return An error message.
' ----------------------------------------------------------------
function BTS__AssertAANotHasKeys(array as dynamic, keys as object, msg = "" as string) as string
    if not TF_Utils__IsAssociativeArray(array)
        return "Input value is not an Associative Array."
    end if

    if not TF_Utils__IsArray(keys) or keys.Count() = 0
        return "Keys value is not an Array or is empty."
    end if

    if TF_Utils__IsAssociativeArray(array) and TF_Utils__IsArray(keys)
        for each key in keys
            if not TF_Utils__IsString(key)
                return "Key value has invalid type."
            end if

            if array.DoesExist(key)
                if msg = ""
                    msg = "Array has the '" + key + "' key."
                end if
                return msg
            end if
        end for
    else
        msg = "Input value is not an Associative Array."
        return msg
    end if
    return ""
end function

' ----------------------------------------------------------------
' Fail if the array doesn't have the item.

' @param array (dynamic) A target array.
' @param value (dynamic) A value to check.
' @param key (object) A key name for associative array.
' @param msg (string) An error message.
' Default value: ""

' @return An error message.
' ----------------------------------------------------------------
function BTS__AssertArrayContains(array as dynamic, value as dynamic, key = invalid as dynamic, msg = "" as string) as string
    if key <> invalid and not TF_Utils__IsString(key)
        return "Key value has invalid type."
    end if

    if TF_Utils__IsAssociativeArray(array) or TF_Utils__IsArray(array)
        if not TF_Utils__ArrayContains(array, value, key)
            msg = "Array doesn't have the '" + TF_Utils__AsString(value) + "' value."

            return msg
        end if
    else
        msg = "Input value is not an Array."

        return msg
    end if

    return ""
end function

' ----------------------------------------------------------------
' Fail if the array has the item.

' @param array (dynamic) A target array.
' @param value (dynamic) A value to check.
' @param key (object) A key name for associative array.
' @param msg (string) An error message.
' Default value: ""

' @return An error message.
' ----------------------------------------------------------------
function BTS__AssertArrayNotContains(array as dynamic, value as dynamic, key = invalid as dynamic, msg = "" as string) as string
    if key <> invalid and not TF_Utils__IsString(key)
        return "Key value has invalid type."
    end if

    if TF_Utils__IsAssociativeArray(array) or TF_Utils__IsArray(array)
        if TF_Utils__ArrayContains(array, value, key)
            msg = "Array has the '" + TF_Utils__AsString(value) + "' value."

            return msg
        end if
    else
        msg = "Input value is not an Array."

        return msg
    end if

    return ""
end function

' ----------------------------------------------------------------
' Fail if the array doesn't have the item subset.

' @param array (dynamic) A target array.
' @param subset (dynamic) An items array to check.
' @param msg (string) An error message.
' Default value: ""

' @return An error message.
' ----------------------------------------------------------------
function BTS__AssertArrayContainsSubset(array as dynamic, subset as dynamic, msg = "" as string) as string
    if (TF_Utils__IsAssociativeArray(array) and TF_Utils__IsAssociativeArray(subset)) or (TF_Utils__IsArray(array) and TF_Utils__IsArray(subset))
        isAA = TF_Utils__IsAssociativeArray(subset)
        for each item in subset
            key = invalid
            value = item
            if isAA
                key = item
                value = subset[key]
            end if

            if not TF_Utils__ArrayContains(array, value, key)
                msg = "Array doesn't have the '" + TF_Utils__AsString(value) + "' value."

                return msg
            end if
        end for
    else
        msg = "Input value is not an Array."

        return msg
    end if

    return ""
end function

' ----------------------------------------------------------------
' Fail if the array have the item from subset.

' @param array (dynamic) A target array.
' @param subset (dynamic) A items array to check.
' @param msg (string) An error message.
' Default value: ""

' @return An error message.
' ----------------------------------------------------------------
function BTS__AssertArrayNotContainsSubset(array as dynamic, subset as dynamic, msg = "" as string) as string
    if (TF_Utils__IsAssociativeArray(array) and TF_Utils__IsAssociativeArray(subset)) or (TF_Utils__IsArray(array) and TF_Utils__IsArray(subset))
        isAA = TF_Utils__IsAssociativeArray(subset)
        for each item in subset
            key = invalid
            value = item
            if isAA
                key = item
                value = subset[key]
            end if

            if TF_Utils__ArrayContains(array, value, key)
                msg = "Array has the '" + TF_Utils__AsString(value) + "' value."

                return msg
            end if
        end for
    else
        msg = "Input value is not an Array."

        return msg
    end if

    return ""
end function

' ----------------------------------------------------------------
' Fail if the array items count <> expected count

' @param array (dynamic) A target array.
' @param count (integer) An expected array items count.
' @param msg (string) An error message.
' Default value: ""

' @return An error message.
' ----------------------------------------------------------------
function BTS__AssertArrayCount(array as dynamic, count as dynamic, msg = "" as string) as string
    if not TF_Utils__IsInteger(count)
        return "Count value should be an integer."
    end if

    if TF_Utils__IsAssociativeArray(array) or TF_Utils__IsArray(array)
        if array.Count() <> count
            msg = "Array items count <> " + TF_Utils__AsString(count) + "."

            return msg
        end if
    else
        msg = "Input value is not an Array."

        return msg
    end if

    return ""
end function

' ----------------------------------------------------------------
' Fail if the array items count = expected count.

' @param array (dynamic) A target array.
' @param count (integer) An expected array items count.
' @param msg (string) An error message.
' Default value: ""

' @return An error message.
' ----------------------------------------------------------------
function BTS__AssertArrayNotCount(array as dynamic, count as dynamic, msg = "" as string) as string
    if not TF_Utils__IsInteger(count)
        return "Count value should be an integer."
    end if

    if TF_Utils__IsAssociativeArray(array) or TF_Utils__IsArray(array)
        if array.Count() = count
            msg = "Array items count = " + TF_Utils__AsString(count) + "."

            return msg
        end if
    else
        msg = "Input value is not an Array."

        return msg
    end if

    return ""
end function

' ----------------------------------------------------------------
' Fail if the item is not empty array or string.

' @param item (dynamic) An array or string to check.
' @param msg (string) An error message.
' Default value: ""

' @return An error message.
' ----------------------------------------------------------------
function BTS__AssertEmpty(item as dynamic, msg = "" as string) as string
    if TF_Utils__IsAssociativeArray(item) or TF_Utils__IsArray(item)
        if item.Count() > 0
            msg = "Array is not empty."

            return msg
        end if
    else if TF_Utils__IsString(item)
        if Len(item) <> 0
            msg = "Input value is not empty."

            return msg
        end if
    else
        msg = "Input value is not an Array, AssociativeArray or String."

        return msg
    end if

    return ""
end function

' ----------------------------------------------------------------
' Fail if the item is empty array or string.

' @param item (dynamic) An array or string to check.
' @param msg (string) An error message.
' Default value: ""

' @return An error message.
' ----------------------------------------------------------------
function BTS__AssertNotEmpty(item as dynamic, msg = "" as string) as string
    if TF_Utils__IsAssociativeArray(item) or TF_Utils__IsArray(item)
        if item.Count() = 0
            msg = "Array is empty."

            return msg
        end if
    else if TF_Utils__IsString(item)
        if Len(item) = 0
            msg = "Input value is empty."

            return msg
        end if
    else
        msg = "Input value is not an Array, AssociativeArray or String."

        return msg
    end if

    return ""
end function

'*****************************************************************
'* Copyright Roku 2011-2019
'* All Rights Reserved
'*****************************************************************

' Functions in this file:
'     ItemGenerator
'     IG_GetItem
'     IG_GetAssocArray
'     IG_GetArray
'     IG_GetSimpleType
'     IG_GetBoolean
'     IG_GetInteger
'     IG_GetFloat
'     IG_GetString

' ----------------------------------------------------------------
' Main function to generate object according to specified scheme.

' @param scheme (object) A scheme with desired object structure. Can be
' any simple type, array of types or associative array in form
'     { propertyName1 : "propertyType1"
'       propertyName2 : "propertyType2"
'       ...
'       propertyNameN : "propertyTypeN" }

' @return An object according to specified scheme or invalid,
' if scheme is not valid.
' ----------------------------------------------------------------
function ItemGenerator(scheme as object) as object
    this = {}

    this.getItem = IG_GetItem
    this.getAssocArray = IG_GetAssocArray
    this.getArray = IG_GetArray
    this.getSimpleType = IG_GetSimpleType
    this.getInteger = IG_GetInteger
    this.getFloat = IG_GetFloat
    this.getString = IG_GetString
    this.getBoolean = IG_GetBoolean

    if not TF_Utils__IsValid(scheme)
        return invalid
    end if

    return this.getItem(scheme)
end function

' TODO: Create IG_GetInvalidItem function with random type fields

' ----------------------------------------------------------------
' Generate object according to specified scheme.

' @param scheme (object) A scheme with desired object structure.
' Can be any simple type, array of types or associative array.

' @return An object according to specified scheme or invalid,
' if scheme is not one of simple type, array or
' associative array.
' ----------------------------------------------------------------
function IG_GetItem(scheme as object) as object
    item = invalid

    if TF_Utils__IsAssociativeArray(scheme)
        item = IG_GetAssocArray(scheme)
    else if TF_Utils__IsArray(scheme)
        item = IG_GetArray(scheme)
    else if TF_Utils__IsString(scheme)
        item = IG_GetSimpleType(LCase(scheme))
    end if

    return item
end function

' ----------------------------------------------------------------
' Generates associative array according to specified scheme.

' @param scheme (object) An associative array with desired
'    object structure in form
'     { propertyName1 : "propertyType1"
'       propertyName2 : "propertyType2"
'       ...
'       propertyNameN : "propertyTypeN" }

' @return An associative array according to specified scheme.
' ----------------------------------------------------------------
function IG_GetAssocArray(scheme as object) as object
    item = {}

    for each key in scheme
        if not item.DoesExist(key)
            item[key] = IG_GetItem(scheme[key])
        end if
    end for

    return item
end function

' ----------------------------------------------------------------
' Generates array according to specified scheme.

' @param scheme (object) An array with desired object types.

' @return An array according to specified scheme.
' ----------------------------------------------------------------
function IG_GetArray(scheme as object) as object
    item = []

    for each key in scheme
        item.Push(IG_GetItem(key))
    end for

    return item
end function

' ----------------------------------------------------------------
' Generates random value of specified type.

' @param typeStr (string) A name of desired object type.

' @return A simple type object or invalid if type is not supported.
' ----------------------------------------------------------------
function IG_GetSimpleType(typeStr as string) as object
    item = invalid

    if typeStr = "integer" or typeStr = "int" or typeStr = "roint"
        item = IG_GetInteger()
    else if typeStr = "float" or typeStr = "rofloat"
        item = IG_GetFloat()
    else if typeStr = "string" or typeStr = "rostring"
        item = IG_GetString(10)
    else if typeStr = "boolean" or typeStr = "roboolean"
        item = IG_GetBoolean()
    end if

    return item
end function

' ----------------------------------------------------------------
' Generates random boolean value.

' @return A random boolean value.
' ----------------------------------------------------------------
function IG_GetBoolean() as boolean
    return TF_Utils__AsBoolean(Rnd(2) \ Rnd(2))
end function

' ----------------------------------------------------------------
' Generates random integer value from 1 to specified seed value.

' @param seed (integer) A seed value for Rnd function.
' Default value: 100.

' @return A random integer value.
' ----------------------------------------------------------------
function IG_GetInteger(seed = 100 as integer) as integer
    return Rnd(seed)
end function

' ----------------------------------------------------------------
' Generates random float value.

' @return A random float value.
' ----------------------------------------------------------------
function IG_GetFloat() as float
    return Rnd(0)
end function

' ----------------------------------------------------------------
' Generates random string with specified length.

' @param seed (integer) A string length.

' @return A random string value or empty string if seed is 0.
' ----------------------------------------------------------------
function IG_GetString(seed as integer) as string
    item = ""
    if seed > 0
        stringLength = Rnd(seed)

        for i = 0 to stringLength
            chType = Rnd(3)

            if chType = 1 ' Chr(48-57) - numbers
                chNumber = 47 + Rnd(10)
            else if chType = 2 ' Chr(65-90) - Uppercase Letters
                chNumber = 64 + Rnd(26)
            else ' Chr(97-122) - Lowercase Letters
                chNumber = 96 + Rnd(26)
            end if

            item = item + Chr(chNumber)
        end for
    end if

    return item
end function
'*****************************************************************
'* Copyright Roku 2011-2019
'* All Rights Reserved
'*****************************************************************

' Functions in this file:
'        Logger
'        Logger__SetVerbosity
'        Logger__SetEcho
'        Logger__SetServerURL
'        Logger__PrintStatistic
'        Logger__SendToServer
'        Logger__CreateTotalStatistic
'        Logger__CreateSuiteStatistic
'        Logger__CreateTestStatistic
'        Logger__AppendSuiteStatistic
'        Logger__AppendTestStatistic
'        Logger__PrintSuiteStatistic
'        Logger__PrintTestStatistic
'        Logger__PrintStart
'        Logger__PrintEnd
'        Logger__PrintSuiteSetUp
'        Logger__PrintSuiteStart
'        Logger__PrintSuiteEnd
'        Logger__PrintSuiteTearDown
'        Logger__PrintTestSetUp
'        Logger__PrintTestStart
'        Logger__PrintTestEnd
'        Logger__PrintTestTearDown

' ----------------------------------------------------------------
' Main function. Create Logger object.

' @return A Logger object.
' ----------------------------------------------------------------
function Logger() as object
    this = {}

    this.verbosityLevel = {
        basic: 0
        normal: 1
        verboseFailed: 2
        verbose: 3
    }

    ' Internal properties
    this.verbosity = this.verbosityLevel.normal
    this.echoEnabled = false
    this.serverURL = ""
    this.jUnitEnabled = false

    ' Interface
    this.SetVerbosity = Logger__SetVerbosity
    this.SetEcho = Logger__SetEcho
    this.SetJUnit = Logger__SetJUnit
    this.SetServer = Logger__SetServer
    this.SetServerURL = Logger__SetServerURL ' Deprecated. Use Logger__SetServer instead.
    this.PrintStatistic = Logger__PrintStatistic
    this.SendToServer = Logger__SendToServer

    this.CreateTotalStatistic = Logger__CreateTotalStatistic
    this.CreateSuiteStatistic = Logger__CreateSuiteStatistic
    this.CreateTestStatistic = Logger__CreateTestStatistic
    this.AppendSuiteStatistic = Logger__AppendSuiteStatistic
    this.AppendTestStatistic = Logger__AppendTestStatistic

    ' Internal functions
    this.PrintSuiteStatistic = Logger__PrintSuiteStatistic
    this.PrintTestStatistic = Logger__PrintTestStatistic
    this.PrintStart = Logger__PrintStart
    this.PrintEnd = Logger__PrintEnd
    this.PrintSuiteSetUp = Logger__PrintSuiteSetUp
    this.PrintSuiteStart = Logger__PrintSuiteStart
    this.PrintSuiteEnd = Logger__PrintSuiteEnd
    this.PrintSuiteTearDown = Logger__PrintSuiteTearDown
    this.PrintTestSetUp = Logger__PrintTestSetUp
    this.PrintTestStart = Logger__PrintTestStart
    this.PrintTestEnd = Logger__PrintTestEnd
    this.PrintTestTearDown = Logger__PrintTestTearDown
    this.PrintJUnitFormat = Logger__PrintJUnitFormat

    return this
end function

' ----------------------------------------------------------------
' Set logging verbosity parameter.

' @param verbosity (integer) A verbosity level.
' Posible values:
'     0 - basic
'     1 - normal
'     2 - verbose failed tests
'     3 - verbose
' Default level: 1
' ----------------------------------------------------------------
sub Logger__SetVerbosity(verbosity = m.verbosityLevel.normal as integer)
    if verbosity >= m.verbosityLevel.basic and verbosity <= m.verbosityLevel.verbose
        m.verbosity = verbosity
    end if
end sub

' ----------------------------------------------------------------
' Set logging echo parameter.

' @param enable (boolean) A echo trigger.
' Posible values: true or false
' Default value: false
' ----------------------------------------------------------------
sub Logger__SetEcho(enable = false as boolean)
    m.echoEnabled = enable
end sub

' ----------------------------------------------------------------
' Set logging JUnit output parameter.

' @param enable (boolean) A JUnit output trigger.
' Posible values: true or false
' Default value: false
' ----------------------------------------------------------------
sub Logger__SetJUnit(enable = false as boolean)
    m.jUnitEnabled = enable
end sub

' ----------------------------------------------------------------
' Set storage server parameters.

' @param url (string) Storage server host.
' Default value: ""
' @param port (string) Storage server port.
' Default value: ""
' ----------------------------------------------------------------
sub Logger__SetServer(host = "" as string, port = "" as string)
    if TF_Utils__IsNotEmptyString(host)
        if TF_Utils__IsNotEmptyString(port)
            m.serverURL = "http://" + host + ":" + port
        else
            m.serverURL = "http://" + host
        end if
    end if
end sub

' ----------------------------------------------------------------
' Set storage server URL parameter.

' @param url (string) A storage server URL.
' Default value: ""
' ----------------------------------------------------------------
sub Logger__SetServerURL(url = "" as string)
    ? "This function is deprecated. Please use Logger__SetServer(host, port)"
end sub

'----------------------------------------------------------------
' Send test results as a POST json payload.
'
' @param statObj (object) stats of the test run.
' Default value: invalid
' ----------------------------------------------------------------
sub Logger__SendToServer(statObj as object)
    if TF_Utils__IsNotEmptyString(m.serverURL) and TF_Utils__IsValid(statObj)
        ? "***"
        ? "***   Sending statsObj to server: "; m.serverURL

        request = CreateObject("roUrlTransfer")
        request.SetUrl(m.serverURL)
        statString = FormatJson(statObj)

        ? "***   Response: "; request.postFromString(statString)
        ? "***"
        ? "******************************************************************"
    end if
end sub

' ----------------------------------------------------------------
' Print statistic object with specified verbosity.

' @param statObj (object) A statistic object to print.
' ----------------------------------------------------------------
sub Logger__PrintStatistic(statObj as object)
    if not m.echoEnabled
        m.PrintStart()

        if m.verbosity = m.verbosityLevel.normal or m.verbosity = m.verbosityLevel.verboseFailed
            for each testSuite in statObj.Suites
                for each testCase in testSuite.Tests
                    if m.verbosity = m.verbosityLevel.verboseFailed and testCase.result = "Fail"
                        m.printTestStatistic(testCase)
                    else
                        ? "***   "; testSuite.Name; ": "; testCase.Name; " - "; testCase.Result
                    end if
                end for
            end for
        else if m.verbosity = m.verbosityLevel.verbose
            for each testSuite in statObj.Suites
                m.PrintSuiteStatistic(testSuite)
            end for
        end if
    end if

    ? "***"
    ? "***   Total  = "; TF_Utils__AsString(statObj.Total); " ; Passed  = "; statObj.Correct; " ; Failed   = "; statObj.Fail; " ; Skipped   = "; statObj.skipped; " ; Crashes  = "; statObj.Crash;
    ? "***   Time spent: "; statObj.Time; "ms"
    ? "***"

    m.PrintEnd()

    m.SendToServer(statObj)

    if m.jUnitEnabled
        m.printJUnitFormat(statObj)
    end if
end sub

' ----------------------------------------------------------------
' Create an empty statistic object for totals in output log.

' @return An empty statistic object.
' ----------------------------------------------------------------
function Logger__CreateTotalStatistic() as object
    statTotalItem = {
        Suites: []
        Time: 0
        Total: 0
        Correct: 0
        Fail: 0
        Skipped: 0
        Crash: 0
    }

    if m.echoEnabled
        m.PrintStart()
    end if

    return statTotalItem
end function

' ----------------------------------------------------------------
' Create an empty statistic object for test suite with specified name.

' @param name (string) A test suite name for statistic object.

' @return An empty statistic object for test suite.
' ----------------------------------------------------------------
function Logger__CreateSuiteStatistic(name as string) as object
    statSuiteItem = {
        Name: name
        Tests: []
        Time: 0
        Total: 0
        Correct: 0
        Fail: 0
        Skipped: 0
        Crash: 0
    }

    if m.echoEnabled
        if m.verbosity = m.verbosityLevel.verbose
            m.PrintSuiteStart(name)
        end if
    end if

    return statSuiteItem
end function

' ----------------------------------------------------------------
' Create statistic object for test with specified name.

' @param name (string) A test name.
' @param result (string) A result of test running.
' Posible values: "Success", "Fail".
' Default value: "Success"
' @param time (integer) A test running time.
' Default value: 0
' @param errorCode (integer) An error code for failed test.
' Posible values:
'     252 (&hFC) : ERR_NORMAL_END
'     226 (&hE2) : ERR_VALUE_RETURN
'     233 (&hE9) : ERR_USE_OF_UNINIT_VAR
'     020 (&h14) : ERR_DIV_ZERO
'     024 (&h18) : ERR_TM
'     244 (&hF4) : ERR_RO2
'     236 (&hEC) : ERR_RO4
'     002 (&h02) : ERR_SYNTAX
'     241 (&hF1) : ERR_WRONG_NUM_PARAM
' Default value: 0
' @param errorMessage (string) An error message for failed test.

' @return A statistic object for test.
' ----------------------------------------------------------------
function Logger__CreateTestStatistic(name as string, result = "Success" as string, time = 0 as integer, errorCode = 0 as integer, errorMessage = "" as string, isInit = false as boolean) as object
    statTestItem = {
        Name: name
        Result: result
        Time: time
        PerfData: {}
        Error: {
            Code: errorCode
            Message: errorMessage
        }
    }

    if m.echoEnabled and not isInit
        if m.verbosity = m.verbosityLevel.verbose
            m.PrintTestStart(name)
        end if
    end if

    return statTestItem
end function

' ----------------------------------------------------------------
' Append test statistic to test suite statistic.

' @param statSuiteObj (object) A target test suite object.
' @param statTestObj (object) A test statistic to append.
' ----------------------------------------------------------------
sub Logger__AppendTestStatistic(statSuiteObj as object, statTestObj as object)
    if TF_Utils__IsAssociativeArray(statSuiteObj) and TF_Utils__IsAssociativeArray(statTestObj)
        statSuiteObj.Tests.Push(statTestObj)

        if TF_Utils__IsInteger(statTestObj.time)
            statSuiteObj.Time = statSuiteObj.Time + statTestObj.Time
        end if

        statSuiteObj.Total = statSuiteObj.Total + 1

        if LCase(statTestObj.Result) = "success"
            statSuiteObj.Correct = statSuiteObj.Correct + 1
        else if LCase(statTestObj.result) = "fail"
            statSuiteObj.Fail = statSuiteObj.Fail + 1
        else if LCase(statTestObj.result) = "skipped"
            statSuiteObj.skipped++
        else
            statSuiteObj.crash = statSuiteObj.crash + 1
        end if

        if m.echoEnabled
            if m.verbosity = m.verbosityLevel.normal
                ? "***   "; statSuiteObj.Name; ": "; statTestObj.Name; " - "; statTestObj.Result
            else if m.verbosity = m.verbosityLevel.verbose
                m.PrintTestStatistic(statTestObj)
            end if
        end if
    end if
end sub

' ----------------------------------------------------------------
' Append suite statistic to total statistic object.

' @param statTotalObj (object) A target total statistic object.
' @param statSuiteObj (object) A test suite statistic object to append.
' ----------------------------------------------------------------
sub Logger__AppendSuiteStatistic(statTotalObj as object, statSuiteObj as object)
    if TF_Utils__IsAssociativeArray(statTotalObj) and TF_Utils__IsAssociativeArray(statSuiteObj)
        statTotalObj.Suites.Push(statSuiteObj)
        statTotalObj.Time = statTotalObj.Time + statSuiteObj.Time

        if TF_Utils__IsInteger(statSuiteObj.Total)
            statTotalObj.Total = statTotalObj.Total + statSuiteObj.Total
        end if

        if TF_Utils__IsInteger(statSuiteObj.Correct)
            statTotalObj.Correct = statTotalObj.Correct + statSuiteObj.Correct
        end if

        if TF_Utils__IsInteger(statSuiteObj.Fail)
            statTotalObj.Fail = statTotalObj.Fail + statSuiteObj.Fail
        end if

        if TF_Utils__IsInteger(statSuiteObj.skipped)
            statTotalObj.skipped += statSuiteObj.skipped
        end if

        if TF_Utils__IsInteger(statSuiteObj.Crash)
            statTotalObj.Crash = statTotalObj.Crash + statSuiteObj.Crash
        end if

        if m.echoEnabled
            if m.verbosity = m.verbosityLevel.verbose
                m.PrintSuiteStatistic(statSuiteObj)
            end if
        end if
    end if
end sub

' ----------------------------------------------------------------
' Print test suite statistic.

' @param statSuiteObj (object) A target test suite object to print.
' ----------------------------------------------------------------
sub Logger__PrintSuiteStatistic(statSuiteObj as object)
    if not m.echoEnabled
        m.PrintSuiteStart(statSuiteObj.Name)

        for each testCase in statSuiteObj.Tests
            m.PrintTestStatistic(testCase)
        end for
    end if

    ? "==="
    ? "===   Total  = "; TF_Utils__AsString(statSuiteObj.Total); " ; Passed  = "; statSuiteObj.Correct; " ; Failed   = "; statSuiteObj.Fail; " ; Skipped   = "; statSuiteObj.skipped; " ; Crashes  = "; statSuiteObj.Crash;
    ? " Time spent: "; statSuiteObj.Time; "ms"
    ? "==="

    m.PrintSuiteEnd(statSuiteObj.Name)
end sub

' ----------------------------------------------------------------
' Print test statistic.

' @param statTestObj (object) A target test object to print.
' ----------------------------------------------------------------
sub Logger__PrintTestStatistic(statTestObj as object)
    if not m.echoEnabled
        m.PrintTestStart(statTestObj.Name)
    end if

    ? "---   Result:        "; statTestObj.Result
    ? "---   Time:          "; statTestObj.Time

    if LCase(statTestObj.result) = "skipped"
        if Len(statTestObj.message) > 0
            ? "---   Message: "; statTestObj.message
        end if
    else if LCase(statTestObj.Result) <> "success"
        ? "---   Error Code:    "; statTestObj.Error.Code
        ? "---   Error Message: "; statTestObj.Error.Message
    end if

    m.PrintTestEnd(statTestObj.Name)
end sub

' ----------------------------------------------------------------
' Print testting start message.
' ----------------------------------------------------------------
sub Logger__PrintStart()
    ? ""
    ? "******************************************************************"
    ? "******************************************************************"
    ? "*************            Start testing               *************"
    ? "******************************************************************"
end sub

' ----------------------------------------------------------------
' Print testing end message.
' ----------------------------------------------------------------
sub Logger__PrintEnd()
    ? "******************************************************************"
    ? "*************             End testing                *************"
    ? "******************************************************************"
    ? "******************************************************************"
    ? ""
end sub

' ----------------------------------------------------------------
' Print test suite SetUp message.
' ----------------------------------------------------------------
sub Logger__PrintSuiteSetUp(sName as string)
    if m.verbosity = m.verbosityLevel.verbose
        ? "================================================================="
        ? "===   SetUp "; sName; " suite."
        ? "================================================================="
    end if
end sub

' ----------------------------------------------------------------
' Print test suite start message.
' ----------------------------------------------------------------
sub Logger__PrintSuiteStart(sName as string)
    ? "================================================================="
    ? "===   Start "; sName; " suite:"
    ? "==="
end sub

' ----------------------------------------------------------------
' Print test suite end message.
' ----------------------------------------------------------------
sub Logger__PrintSuiteEnd(sName as string)
    ? "==="
    ? "===   End "; sName; " suite."
    ? "================================================================="
end sub

' ----------------------------------------------------------------
' Print test suite TearDown message.
' ----------------------------------------------------------------
sub Logger__PrintSuiteTearDown(sName as string)
    if m.verbosity = m.verbosityLevel.verbose
        ? "================================================================="
        ? "===   TearDown "; sName; " suite."
        ? "================================================================="
    end if
end sub

' ----------------------------------------------------------------
' Print test setUp message.
' ----------------------------------------------------------------
sub Logger__PrintTestSetUp(tName as string)
    if m.verbosity = m.verbosityLevel.verbose
        ? "----------------------------------------------------------------"
        ? "---   SetUp "; tName; " test."
        ? "----------------------------------------------------------------"
    end if
end sub

' ----------------------------------------------------------------
' Print test start message.
' ----------------------------------------------------------------
sub Logger__PrintTestStart(tName as string)
    ? "----------------------------------------------------------------"
    ? "---   Start "; tName; " test:"
    ? "---"
end sub

' ----------------------------------------------------------------
' Print test end message.
' ----------------------------------------------------------------
sub Logger__PrintTestEnd(tName as string)
    ? "---"
    ? "---   End "; tName; " test."
    ? "----------------------------------------------------------------"
end sub

' ----------------------------------------------------------------
' Print test TearDown message.
' ----------------------------------------------------------------
sub Logger__PrintTestTearDown(tName as string)
    if m.verbosity = m.verbosityLevel.verbose
        ? "----------------------------------------------------------------"
        ? "---   TearDown "; tName; " test."
        ? "----------------------------------------------------------------"
    end if
end sub

sub Logger__PrintJUnitFormat(statObj as object)
    ' TODO finish report
    xml = CreateObject("roXMLElement")
    xml.SetName("testsuites")
    for each testSuiteAA in statObj.suites
        testSuite = xml.AddElement("testsuite")
        ' name="FeatureManagerTest" time="13.923" tests="2" errors="0" skipped="0" failures="0"
        testSuite.AddAttribute("name", testSuiteAA.name)
        testSuite.AddAttribute("time", testSuiteAA.time.toStr())
        testSuite.AddAttribute("tests", testSuiteAA.Tests.count().toStr())

        skippedNum = 0
        failedNum = 0
        for each testAA in testSuiteAA.Tests
            test = testSuite.AddElement("testcase")
            test.AddAttribute("name", testAA.name)
            test.AddAttribute("time", testAA.time.toStr())

            if LCase(testAA.result) = "skipped" then
                test.AddElement("skipped")
                skippedNum++
            else if LCase(testAA.Result) <> "success"
                failure = test.AddElement("failure")
                failure.AddAttribute("message", testAA.error.message)
                failure.AddAttribute("type", testAA.error.code.tostr())
                failedNum++
            end if
        end for
        testSuite.AddAttribute("errors", failedNum.tostr())
        testSuite.AddAttribute("skipped", skippedNum.tostr())
    end for
    ? xml.GenXML(true)
end sub
'*****************************************************************
'* Copyright Roku 2011-2019
'* All Rights Reserved
'*****************************************************************

' Functions in this file:
'        TestRunner
'        TestRunner__Run
'        TestRunner__SetTestsDirectory
'        TestRunner__SetTestFilePrefix
'        TestRunner__SetTestSuitePrefix
'        TestRunner__SetTestSuiteName
'        TestRunner__SetTestCaseName
'        TestRunner__SetFailFast
'        TestRunner__GetTestSuitesList
'        TestRunner__GetTestSuiteNamesList
'        TestRunner__GetTestFilesList
'        TestRunner__GetTestNodesList
'        TestFramework__RunNodeTests

' ----------------------------------------------------------------
' Main function. Create TestRunner object.

' @return A TestRunner object.
' ----------------------------------------------------------------
function TestRunner() as object
    this = {}
    GetGlobalAA().globalErrorsList = []
    this.isNodeMode = GetGlobalAA().top <> invalid
    this.Logger = Logger()

    ' Internal properties
    this.SKIP_TEST_MESSAGE_PREFIX = "SKIP_TEST_MESSAGE_PREFIX__"
    this.nodesTestDirectory = "pkg:/components/tests"
    if this.isNodeMode
        this.testsDirectory = this.nodesTestDirectory
        this.testFilePrefix = m.top.subtype()
    else
        this.testsDirectory = "pkg:/source/tests"
        this.testFilePrefix = "Test__"
    end if
    this.testSuitePrefix = "TestSuite__"
    this.testSuiteName = ""
    this.testCaseName = ""
    this.failFast = false

    ' Interface
    this.Run = TestRunner__Run
    this.SetTestsDirectory = TestRunner__SetTestsDirectory
    this.SetTestFilePrefix = TestRunner__SetTestFilePrefix
    this.SetTestSuitePrefix = TestRunner__SetTestSuitePrefix
    this.SetTestSuiteName = TestRunner__SetTestSuiteName ' Obsolete, will be removed in next versions
    this.SetTestCaseName = TestRunner__SetTestCaseName ' Obsolete, will be removed in next versions
    this.SetFailFast = TestRunner__SetFailFast
    this.SetFunctions = TestRunner__SetFunctions
    this.SetIncludeFilter = TestRunner__SetIncludeFilter
    this.SetExcludeFilter = TestRunner__SetExcludeFilter

    ' Internal functions
    this.GetTestFilesList = TestRunner__GetTestFilesList
    this.GetTestSuitesList = TestRunner__GetTestSuitesList
    this.GetTestNodesList = TestRunner__GetTestNodesList
    this.GetTestSuiteNamesList = TestRunner__GetTestSuiteNamesList
    this.GetIncludeFilter = TestRunner__GetIncludeFilter
    this.GetExcludeFilter = TestRunner__GetExcludeFilter

    return this
end function

' ----------------------------------------------------------------
' Run main test loop.

' @param statObj (object, optional) statistic object to be used in tests
' @param testSuiteNamesList (array, optional) array of test suite function names to be used in tests

' @return Statistic object if run in node mode, invalid otherwise
' ----------------------------------------------------------------
function TestRunner__Run(statObj = m.Logger.CreateTotalStatistic() as object, testSuiteNamesList = [] as object) as object
    alltestCount = 0
    totalStatObj = statObj
    testSuitesList = m.GetTestSuitesList(testSuiteNamesList)

    globalErrorsList = GetGlobalAA().globalErrorsList
    for each testSuite in testSuitesList
        testCases = testSuite.testCases
        testCount = testCases.Count()
        alltestCount = alltestCount + testCount

        IS_NEW_APPROACH = testSuite.IS_NEW_APPROACH
        ' create dedicated env for each test, so that they will have not global m and don't rely on m.that is set in another suite
        env = {}

        if TF_Utils__IsFunction(testSuite.SetUp)
            m.Logger.PrintSuiteSetUp(testSuite.Name)
            if IS_NEW_APPROACH then
                env.functionToCall = testSuite.SetUp
                env.functionToCall()
            else
                testSuite.SetUp()
            end if
        end if

        suiteStatObj = m.Logger.CreateSuiteStatistic(testSuite.Name)
        ' Initiate empty test statistics object to print results if no tests was run
        testStatObj = m.Logger.CreateTestStatistic("", "Success", 0, 0, "", true)
        for each testCase in testCases
            ' clear all existing errors
            globalErrorsList.clear()

            if m.testCaseName = "" or (m.testCaseName <> "" and LCase(testCase.Name) = LCase(m.testCaseName))
                skipTest = TF_Utils__AsBoolean(testCase.skip)

                if TF_Utils__IsFunction(testCase.SetUp) and not skipTest
                    m.Logger.PrintTestSetUp(testCase.Name)
                    if IS_NEW_APPROACH then
                        env.functionToCall = testCase.SetUp
                        env.functionToCall()
                    else
                        testCase.SetUp()
                    end if
                end if

                testTimer = CreateObject("roTimespan")
                testStatObj = m.Logger.CreateTestStatistic(testCase.Name)

                if skipTest
                    runResult = m.SKIP_TEST_MESSAGE_PREFIX + "Test was skipped according to specified filters"
                else
                    testSuite.testInstance = testCase
                    testSuite.testCase = testCase.Func

                    runResult = ""
                    if IS_NEW_APPROACH then
                        env.functionToCall = testCase.Func

                        if GetInterface(env.functionToCall, "ifFunction") <> invalid
                            if testCase.hasArguments then
                                env.functionToCall(testCase.arg)
                            else
                                env.functionToCall()
                            end if
                        else
                            UTF_fail("Failed to execute test """ + testCase.Name + """ function pointer not found")
                        end if
                    else
                        runResult = testSuite.testCase()
                    end if
                end if

                if TF_Utils__IsFunction(testCase.TearDown) and not skipTest
                    m.Logger.PrintTestTearDown(testCase.Name)
                    if IS_NEW_APPROACH then
                        env.functionToCall = testCase.TearDown
                        env.functionToCall()
                    else
                        testCase.TearDown()
                    end if
                end if

                if IS_NEW_APPROACH then
                    if globalErrorsList.count() > 0
                        for each error in globalErrorsList
                            runResult += error + Chr(10) + string(10, "-") + Chr(10)
                        end for
                    end if
                end if

                if runResult <> ""
                    if InStr(0, runResult, m.SKIP_TEST_MESSAGE_PREFIX) = 1
                        testStatObj.result = "Skipped"
                        testStatObj.message = runResult.Mid(Len(m.SKIP_TEST_MESSAGE_PREFIX)) ' remove prefix from the message
                    else
                        testStatObj.Result = "Fail"
                        testStatObj.Error.Code = 1
                        testStatObj.Error.Message = runResult
                    end if
                else
                    testStatObj.Result = "Success"
                end if

                testStatObj.Time = testTimer.TotalMilliseconds()
                m.Logger.AppendTestStatistic(suiteStatObj, testStatObj)

                if testStatObj.Result = "Fail" and m.failFast
                    suiteStatObj.Result = "Fail"
                    exit for
                end if
            end if
        end for

        m.Logger.AppendSuiteStatistic(totalStatObj, suiteStatObj)

        if TF_Utils__IsFunction(testSuite.TearDown)
            m.Logger.PrintSuiteTearDown(testSuite.Name)
            testSuite.TearDown()
        end if

        if suiteStatObj.Result = "Fail" and m.failFast
            exit for
        end if
    end for

    gthis = GetGlobalAA()
    msg = ""
    if gthis.notFoundFunctionPointerList <> invalid then
        msg = Chr(10) + string(40, "---") + Chr(10)
        if m.isNodeMode
            fileNamesString = ""

            for each testSuiteObject in testSuiteNamesList
                if GetInterface(testSuiteObject, "ifString") <> invalid then
                    fileNamesString += testSuiteObject + ".brs, "
                else if GetInterface(testSuiteObject, "ifAssociativeArray") <> invalid then
                    if testSuiteObject.filePath <> invalid then
                        fileNamesString += testSuiteObject.filePath + ", "
                    end if
                end if
            end for

            msg += Chr(10) + "Create this function below in one of these files"
            msg += Chr(10) + fileNamesString + Chr(10)

            msg += Chr(10) + "sub init()"
        end if
        msg += Chr(10) + "Runner.SetFunctions([" + Chr(10) + "    testCase" + Chr(10) + "])"
        msg += Chr(10) + "For example we think this might resolve your issue"
        msg += Chr(10) + "Runner = TestRunner()"
        msg += Chr(10) + "Runner.SetFunctions(["

        tmpMap = {}
        for each functionName in gthis.notFoundFunctionPointerList
            if tmpMap[functionName] = invalid then
                tmpMap[functionName] = ""
                msg += Chr(10) + "    " + functionName
            end if
        end for

        msg += Chr(10) + "])"
        if m.isNodeMode then
            msg += Chr(10) + "end sub"
        else
            msg += Chr(10) + "Runner.Run()"
        end if
    end if

    if m.isNodeMode
        if msg.Len() > 0 then
            if totalStatObj.notFoundFunctionsMessage = invalid then totalStatObj.notFoundFunctionsMessage = ""
            totalStatObj.notFoundFunctionsMessage += msg
        end if
        return totalStatObj
    else
        testNodes = m.getTestNodesList()
        for each testNodeName in testNodes
            testNode = CreateObject("roSGNode", testNodeName)
            if testNode <> invalid
                testSuiteNamesList = m.GetTestSuiteNamesList(testNodeName)
                if CreateObject("roSGScreen").CreateScene(testNodeName) <> invalid
                    ? "WARNING: Test cases cannot be run in main scene."
                    for each testSuiteName in testSuiteNamesList
                        suiteStatObj = m.Logger.CreateSuiteStatistic(testSuiteName)
                        suiteStatObj.fail = 1
                        suiteStatObj.total = 1
                        m.Logger.AppendSuiteStatistic(totalStatObj, suiteStatObj)
                    end for
                else
                    params = [m, totalStatObj, testSuiteNamesList, m.GetIncludeFilter(), m.GetExcludeFilter()]
                    tmp = testNode.callFunc("TestFramework__RunNodeTests", params)
                    if tmp <> invalid then
                        totalStatObj = tmp
                    end if
                end if
            end if
        end for

        m.Logger.PrintStatistic(totalStatObj)
    end if

    if msg.Len() > 0 or totalStatObj.notFoundFunctionsMessage <> invalid then
        title = ""
        title += Chr(10) + "NOTE: If some your tests haven't been executed this might be due to outdated list of functions"
        title += Chr(10) + "To resolve this issue please execute" + Chr(10) + Chr(10)

        title += msg

        if totalStatObj.notFoundFunctionsMessage <> invalid then
            title += totalStatObj.notFoundFunctionsMessage
        end if
        ? title
    end if
end function

' ----------------------------------------------------------------
' Set testsDirectory property.
' ----------------------------------------------------------------
sub TestRunner__SetTestsDirectory(testsDirectory as string)
    m.testsDirectory = testsDirectory
end sub

' ----------------------------------------------------------------
' Set testFilePrefix property.
' ----------------------------------------------------------------
sub TestRunner__SetTestFilePrefix(testFilePrefix as string)
    m.testFilePrefix = testFilePrefix
end sub

' ----------------------------------------------------------------
' Set testSuitePrefix property.
' ----------------------------------------------------------------
sub TestRunner__SetTestSuitePrefix(testSuitePrefix as string)
    m.testSuitePrefix = testSuitePrefix
end sub

' ----------------------------------------------------------------
' Set testSuiteName property.
' ----------------------------------------------------------------
sub TestRunner__SetTestSuiteName(testSuiteName as string)
    m.testSuiteName = testSuiteName
end sub

' ----------------------------------------------------------------
' Set testCaseName property.
' ----------------------------------------------------------------
sub TestRunner__SetTestCaseName(testCaseName as string)
    m.testCaseName = testCaseName
end sub

' ----------------------------------------------------------------
' Set failFast property.
' ----------------------------------------------------------------
sub TestRunner__SetFailFast(failFast = false as boolean)
    m.failFast = failFast
end sub

' ----------------------------------------------------------------
' Builds an array of test suite objects.

' @param testSuiteNamesList (string, optional) array of names of test suite functions. If not passed, scans all test files for test suites

' @return An array of test suites.
' ----------------------------------------------------------------
function TestRunner__GetTestSuitesList(testSuiteNamesList = [] as object) as object
    result = []

    if testSuiteNamesList.count() > 0
        for each value in testSuiteNamesList
            if TF_Utils__IsString(value) then
                tmpTestSuiteFunction = TestFramework__getFunctionPointer(value)
                if tmpTestSuiteFunction <> invalid then
                    testSuite = tmpTestSuiteFunction()

                    if TF_Utils__IsAssociativeArray(testSuite)
                        result.Push(testSuite)
                    end if
                end if
                ' also we can get AA that will give source code and filePath
                ' Please be aware this is executed in render thread
            else if GetInterface(value, "ifAssociativeArray") <> invalid then
                ' try to use new approach
                testSuite = ScanFileForNewTests(value.code, value.filePath)
                if testSuite <> invalid then
                    result.push(testSuite)
                end if
            else if GetInterface(value, "ifFunction") <> invalid then
                result.Push(value)
            end if
        end for
    else
        testSuiteRegex = CreateObject("roRegex", "^(function|sub)\s(" + m.testSuitePrefix + m.testSuiteName + "[0-9a-z\_]*)\s*\(", "i")
        testFilesList = m.GetTestFilesList()

        for each filePath in testFilesList
            code = TF_Utils__AsString(ReadAsciiFile(filePath))

            if code <> ""
                foundTestSuite = false
                for each line in code.Tokenize(Chr(10))
                    line.Trim()

                    if testSuiteRegex.IsMatch(line)
                        testSuite = invalid
                        functionName = testSuiteRegex.Match(line).Peek()

                        tmpTestSuiteFunction = TestFramework__getFunctionPointer(functionName)
                        if tmpTestSuiteFunction <> invalid then
                            testSuite = tmpTestSuiteFunction()

                            if TF_Utils__IsAssociativeArray(testSuite)
                                result.Push(testSuite)
                                foundTestSuite = true
                            else
                                ' TODO check if we need this
                                ' using new mode
                                '                          testSuite = ScanFileForNewTests(code, filePath)

                                '                          exit for
                            end if
                        end if
                    end if
                end for
                if not foundTestSuite then
                    testSuite = ScanFileForNewTests(code, filePath)
                    if testSuite <> invalid then
                        result.push(testSuite)
                    end if
                end if
            end if
        end for
    end if

    return result
end function

function ScanFileForNewTests(souceCode, filePath)
    foundAnyTest = false
    testSuite = BaseTestSuite()

    allowedAnnotationsRegex = CreateObject("roRegex", "^'\s*@(test|beforeall|beforeeach|afterall|aftereach|repeatedtest|parameterizedtest|methodsource|ignore)\s*|\n", "i")
    voidFunctionRegex = CreateObject("roRegex", "^(function|sub)\s([a-z0-9A-Z_]*)\(\)", "i")
    anyArgsFunctionRegex = CreateObject("roRegex", "^(function|sub)\s([a-z0-9A-Z_]*)\(", "i")

    processors = {
        testSuite: testSuite
        filePath: filePath
        currentLine: ""
        annotations: {}

        functionName: ""

        tests: []

        beforeEachFunc: invalid
        beforeAllFunc: invalid

        AfterEachFunc: invalid
        AfterAllFunc: invalid

        isParameterizedTest: false
        MethodForArguments: ""
        executedParametrizedAdding: false

        test: sub()
            skipTest = m.doSkipTest(m.functionName)
            funcPointer = m.getFunctionPointer(m.functionName)
            m.tests.push({ name: m.functionName, pointer: funcPointer, skip: skipTest })
        end sub

        repeatedtest: sub()
            allowedAnnotationsRegex = CreateObject("roRegex", "^'\s*@(repeatedtest)\((\d*)\)", "i")
            annotationLine = m.annotations["repeatedtest"].line
            if allowedAnnotationsRegex.IsMatch(annotationLine)
                groups = allowedAnnotationsRegex.Match(annotationLine)
                numberOfLoops = groups[2]
                if numberOfLoops <> invalid and TF_Utils__AsInteger(numberOfLoops) > 0 then
                    numberOfLoops = TF_Utils__AsInteger(numberOfLoops)
                    funcPointer = m.getFunctionPointer(m.functionName)
                    for index = 1 to numberOfLoops
                        skipTest = m.doSkipTest(m.functionName)
                        text = " " + index.tostr() + " of " + numberOfLoops.tostr()
                        m.tests.push({ name: m.functionName + text, pointer: funcPointer, skip: skipTest })
                    end for
                end if
            else
                ? "WARNING: Wrong format of repeatedTest(numberOfRuns) "annotationLine
            end if
        end sub

        parameterizedTest: sub()
            m.processParameterizedTests()
        end sub

        methodSource: sub()
            m.processParameterizedTests()
        end sub

        processParameterizedTests: sub()
            ' add test if it was not added already
            if not m.executedParametrizedAdding
                if m.annotations.methodSource <> invalid and m.annotations.parameterizedTest <> invalid then
                    methodAnottation = m.annotations.methodSource.line

                    allowedAnnotationsRegex = CreateObject("roRegex", "^'\s*@(methodsource)\(" + Chr(34) + "([A-Za-z0-9_]*)" + Chr(34) + "\)", "i")

                    if allowedAnnotationsRegex.IsMatch(methodAnottation)
                        groups = allowedAnnotationsRegex.Match(methodAnottation)
                        providerFunction = groups[2]

                        providerFunctionPointer = m.getFunctionPointer(providerFunction)

                        if providerFunctionPointer <> invalid then
                            funcPointer = m.getFunctionPointer(m.functionName)

                            args = providerFunctionPointer()

                            index = 1
                            for each arg in args
                                skipTest = m.doSkipTest(m.functionName)
                                text = " " + index.tostr() + " of " + args.count().tostr()
                                m.tests.push({ name: m.functionName + text, pointer: funcPointer, arg: arg, hasArgs: true, skip: skipTest })
                                index++
                            end for
                        else
                            ? "WARNING: Cannot find function [" providerFunction "]"
                        end if
                    end if
                else
                    ? "WARNING: Wrong format of  @ParameterizedTest \n @MethodSource(providerFunctionName)"
                    ? "m.executedParametrizedAdding = "m.executedParametrizedAdding
                    ? "m.annotations.methodSource = "m.annotations.methodSource
                    ? "m.annotations.parameterizedTest = "m.annotations.parameterizedTest
                    ? ""
                end if
            end if
        end sub

        beforeEach: sub()
            m.beforeEachFunc = m.getFunctionPointer(m.functionName)
        end sub

        beforeAll: sub()
            m.beforeAllFunc = m.getFunctionPointer(m.functionName)
        end sub

        AfterEach: sub()
            m.AfterEachFunc = m.getFunctionPointer(m.functionName)
        end sub

        AfterAll: sub()
            m.AfterAllFunc = m.getFunctionPointer(m.functionName)
        end sub

        ignore: sub()
            funcPointer = m.getFunctionPointer(m.functionName)
            m.tests.push({ name: m.functionName, pointer: funcPointer, skip: true })
        end sub

        doSkipTest: function(name as string)
            includeFilter = []
            excludeFilter = []

            gthis = GetGlobalAA()
            if gthis.IncludeFilter <> invalid then includeFilter.append(gthis.IncludeFilter)
            if gthis.ExcludeFilter <> invalid then excludeFilter.append(gthis.ExcludeFilter)

            ' apply test filters
            skipTest = false
            ' skip test if it is found in exclude filter
            for each testName in excludeFilter
                if TF_Utils__IsNotEmptyString(testName) and LCase(testName.Trim()) = LCase(name.Trim())
                    skipTest = true
                    exit for
                end if
            end for

            ' skip test if it is not found in include filter
            if not skipTest and includeFilter.Count() > 0
                foundInIncludeFilter = false

                for each testName in includeFilter
                    if TF_Utils__IsNotEmptyString(testName) and LCase(testName) = LCase(name)
                        foundInIncludeFilter = true
                        exit for
                    end if
                end for

                skipTest = not foundInIncludeFilter
            end if

            return skipTest
        end function

        buildTests: sub()
            testSuite = m.testSuite
            testSuite.Name = m.filePath
            if m.beforeAllFunc <> invalid then testSuite.SetUp = m.beforeAllFunc
            if m.AfterAllFunc <> invalid then testSuite.TearDown = m.AfterAllFunc
            testSuite.IS_NEW_APPROACH = true

            for each test in m.tests
                ' Add tests to suite's tests collection
                arg = invalid
                hasArgs = false
                if test.hasArgs <> invalid then
                    arg = test.arg
                    hasArgs = true
                end if

                testSuite.addTest(test.name, test.pointer, m.beforeEachFunc, m.AfterEachFunc, arg, hasArgs, test.skip)
            end for
        end sub

        getFunctionPointer: TestFramework__getFunctionPointer
    }

    currentAnottations = []
    index = 0

    for each line in souceCode.Tokenize(Chr(10))
        line = line.Trim()
        if line <> "" ' skipping empty lines
            if allowedAnnotationsRegex.IsMatch(line)
                groups = allowedAnnotationsRegex.Match(line)
                anottationType = groups[1]
                if anottationType <> invalid and processors[anottationType] <> invalid then
                    currentAnottations.push(anottationType)
                    processors.annotations[anottationType] = { line: line, lineIndex: index }
                end if
            else
                if currentAnottations.count() > 0 then
                    isParametrized = anyArgsFunctionRegex.IsMatch(line)
                    properMap = { parameterizedtest: "", methodsource: "" }
                    for each availableAnottation in currentAnottations
                        isParametrized = isParametrized or properMap[availableAnottation] <> invalid
                    end for

                    if voidFunctionRegex.IsMatch(line) or isParametrized then
                        groups = voidFunctionRegex.Match(line)

                        if isParametrized then
                            groups = anyArgsFunctionRegex.Match(line)
                        end if
                        if groups[2] <> invalid then
                            processors.functionName = groups[2]
                            processors.currentLine = line

                            ' process all handlers
                            if isParametrized then processors.executedParametrizedAdding = false
                            for each availableAnottation in currentAnottations
                                processors[availableAnottation]()
                                if isParametrized then processors.executedParametrizedAdding = true
                            end for
                            currentAnottations = []
                            processors.annotations = {}
                            foundAnyTest = true
                        end if
                    else
                        ' invalidating annotation
                        ' TODO print message here that we skipped annotation
                        ? "WARNING: annotation " currentAnottations " isparametrized=" isParametrized " skipped at line " index ":[" line "]"
                        processors.annotations = {}
                        currentAnottations = []
                    end if
                end if
            end if
        end if
        index++
    end for

    processors.buildTests()

    if not foundAnyTest then
        testSuite = invalid
    end if
    return testSuite
end function

function TestFramework__getFunctionPointer(functionName as string) as dynamic
    result = invalid

    gthis = GetGlobalAA()
    if gthis.FunctionsList <> invalid then
        for each value in gthis.FunctionsList
            if Type(value) <> "" and LCase(Type(value)) <> "<uninitialized>" and GetInterface(value, "ifFunction") <> invalid and LCase(value.tostr()) = "function: " + LCase(functionName) then
                result = value
                exit for
            end if
        end for
    end if

    if LCase(Type(result)) = "<uninitialized>" then result = invalid
    if result = invalid then
        if gthis.notFoundFunctionPointerList = invalid then gthis.notFoundFunctionPointerList = []
        gthis.notFoundFunctionPointerList.push(functionName)
    end if
    return result
end function

sub TestRunner__SetFunctions(listOfFunctions as dynamic)
    gthis = GetGlobalAA()

    if gthis.FunctionsList = invalid then
        gthis.FunctionsList = []
    end if
    gthis.FunctionsList.append(listOfFunctions)
end sub

sub TestRunner__SetIncludeFilter(listOfFunctions as dynamic)
    gthis = GetGlobalAA()

    if gthis.IncludeFilter = invalid
        gthis.IncludeFilter = []
    end if

    if TF_Utils__IsArray(listOfFunctions)
        gthis.IncludeFilter.Append(listOfFunctions)
    else if TF_Utils__IsNotEmptyString(listOfFunctions)
        gthis.IncludeFilter.Append(listOfFunctions.Split(","))
    else
        ? "WARNING: Could not parse input parameters for Include Filter. Filter wont be applied."
    end if
end sub

function TestRunner__GetIncludeFilter()
    gthis = GetGlobalAA()

    if gthis.IncludeFilter = invalid
        gthis.IncludeFilter = []
    end if

    return gthis.IncludeFilter
end function

sub TestRunner__SetExcludeFilter(listOfFunctions as dynamic)
    gthis = GetGlobalAA()

    if gthis.ExcludeFilter = invalid
        gthis.ExcludeFilter = []
    end if

    if TF_Utils__IsArray(listOfFunctions)
        gthis.ExcludeFilter.Append(listOfFunctions)
    else if TF_Utils__IsNotEmptyString(listOfFunctions)
        gthis.ExcludeFilter.Append(listOfFunctions.Split(","))
    else
        ? "WARNING: Could not parse input parameters for Exclude Filter. Filter wont be applied."
    end if
end sub

function TestRunner__GetExcludeFilter()
    gthis = GetGlobalAA()

    if gthis.ExcludeFilter = invalid
        gthis.ExcludeFilter = []
    end if

    return gthis.ExcludeFilter
end function

' ----------------------------------------------------------------
' Scans all test files for test suite function names for a given test node.

' @param testNodeName (string) name of a test node, test suites for which are needed

' @return An array of test suite names.
' ----------------------------------------------------------------
function TestRunner__GetTestSuiteNamesList(testNodeName as string) as object
    result = []
    testSuiteRegex = CreateObject("roRegex", "^(function|sub)\s(" + m.testSuitePrefix + m.testSuiteName + "[0-9a-z\_]*)\s*\(", "i")
    testFilesList = m.GetTestFilesList(m.nodesTestDirectory, testNodeName)

    for each filePath in testFilesList
        code = TF_Utils__AsString(ReadAsciiFile(filePath))

        if code <> ""
            foundTestSuite = false
            for each line in code.Tokenize(Chr(10))
                line.Trim()

                if testSuiteRegex.IsMatch(line)
                    functionName = testSuiteRegex.Match(line).Peek()
                    result.Push(functionName)
                    foundTestSuite = true
                end if
            end for

            if not foundTestSuite then
                ' we cannot scan for new tests as we are not in proper scope
                ' so we need to pass some data so this can be executed in render thread
                result.push({ filePath: filePath, code: code })
            end if
        end if
    end for

    return result
end function

' ----------------------------------------------------------------
' Scan testsDirectory and all subdirectories for test files.

' @param testsDirectory (string, optional) A target directory with test files.
' @param testFilePrefix (string, optional) prefix, used by test files

' @return An array of test files.
' ----------------------------------------------------------------
function TestRunner__GetTestFilesList(testsDirectory = m.testsDirectory as string, testFilePrefix = m.testFilePrefix as string) as object
    result = []
    testsFileRegex = CreateObject("roRegex", "^(" + testFilePrefix + ")[0-9a-z\_]*\.brs$", "i")

    if testsDirectory <> ""
        fileSystem = CreateObject("roFileSystem")

        if m.isNodeMode
            ? string(2, Chr(10))
            ? string(10, "!!!")
            ? "Note if you crash here this means that we are in render thread and searching for tests"
            ? "Problem is that file naming is wrong"
            ? "check brs file name they should match pattern ""Test_ExactComponentName_anything.brs"""
            ? "In this case we were looking for "testFilePrefix
            ? string(10, "!!!") string(2, Chr(10))
        end if
        listing = fileSystem.GetDirectoryListing(testsDirectory)

        for each item in listing
            itemPath = testsDirectory + "/" + item
            itemStat = fileSystem.Stat(itemPath)

            if itemStat.type = "directory" then
                result.Append(m.getTestFilesList(itemPath, testFilePrefix))
            else if testsFileRegex.IsMatch(item) then
                result.Push(itemPath)
            end if
        end for
    end if

    return result
end function

' ----------------------------------------------------------------
' Scan nodesTestDirectory and all subdirectories for test nodes.

' @param nodesTestDirectory (string, optional) A target directory with test nodes.

' @return An array of test node names.
' ----------------------------------------------------------------
function TestRunner__GetTestNodesList(testsDirectory = m.nodesTestDirectory as string) as object
    result = []
    testsFileRegex = CreateObject("roRegex", "^(" + m.testFilePrefix + ")[0-9a-z\_]*\.xml$", "i")

    if testsDirectory <> ""
        fileSystem = CreateObject("roFileSystem")
        listing = fileSystem.GetDirectoryListing(testsDirectory)

        for each item in listing
            itemPath = testsDirectory + "/" + item
            itemStat = fileSystem.Stat(itemPath)

            if itemStat.type = "directory" then
                result.Append(m.getTestNodesList(itemPath))
            else if testsFileRegex.IsMatch(item) then
                result.Push(item.replace(".xml", ""))
            end if
        end for
    end if

    return result
end function

' ----------------------------------------------------------------
' Creates and runs test runner. Should be used ONLY within a node.

' @param params (array) parameters, passed from main thread, used to setup new test runner

' @return statistic object.
' ----------------------------------------------------------------
function TestFramework__RunNodeTests(params as object) as object
    this = params[0]

    statObj = params[1]
    testSuiteNamesList = params[2]

    Runner = TestRunner()

    Runner.SetTestSuitePrefix(this.testSuitePrefix)
    Runner.SetTestFilePrefix(this.testFilePrefix)
    Runner.SetTestSuiteName(this.testSuiteName)
    Runner.SetTestCaseName(this.testCaseName)
    Runner.SetFailFast(this.failFast)

    Runner.SetIncludeFilter(params[3])
    Runner.SetExcludeFilter(params[4])

    return Runner.Run(statObj, testSuiteNamesList)
end function
function UTF_skip(msg = "")
    return UTF_PushErrorMessage(BTS__Skip(msg))
end function

function UTF_fail(msg = "")
    return UTF_PushErrorMessage(BTS__Fail(msg))
end function

function UTF_assertFalse(expr, msg = "Expression evaluates to true")
    return UTF_PushErrorMessage(BTS__AssertFalse(expr, msg))
end function

function UTF_assertTrue(expr, msg = "Expression evaluates to false")
    return UTF_PushErrorMessage(BTS__AssertTrue(expr, msg))
end function

function UTF_assertEqual(first, second, msg = "")
    return UTF_PushErrorMessage(BTS__AssertEqual(first, second, msg))
end function

function UTF_assertNotEqual(first, second, msg = "")
    return UTF_PushErrorMessage(BTS__AssertNotEqual(first, second, msg))
end function

function UTF_assertInvalid(value, msg = "")
    return UTF_PushErrorMessage(BTS__AssertInvalid(value, msg))
end function

function UTF_assertNotInvalid(value, msg = "")
    return UTF_PushErrorMessage(BTS__AssertNotInvalid(value, msg))
end function

function UTF_assertAAHasKey(array, key, msg = "")
    return UTF_PushErrorMessage(BTS__AssertAAHasKey(array, key, msg))
end function

function UTF_assertAANotHasKey(array, key, msg = "")
    return UTF_PushErrorMessage(BTS__AssertAANotHasKey(array, key, msg))
end function

function UTF_assertAAHasKeys(array, keys, msg = "")
    return UTF_PushErrorMessage(BTS__AssertAAHasKeys(array, keys, msg))
end function

function UTF_assertAANotHasKeys(array, keys, msg = "")
    return UTF_PushErrorMessage(BTS__AssertAANotHasKeys(array, keys, msg))
end function

function UTF_assertArrayContains(array, value, key = invalid, msg = "")
    return UTF_PushErrorMessage(BTS__AssertArrayContains(array, value, key, msg))
end function

function UTF_assertArrayNotContains(array, value, key = invalid, msg = "")
    return UTF_PushErrorMessage(BTS__AssertArrayNotContains(array, value, key, msg))
end function

function UTF_assertArrayContainsSubset(array, subset, msg = "")
    return UTF_PushErrorMessage(BTS__AssertArrayContainsSubset(array, subset, msg))
end function

function UTF_assertArrayNotContainsSubset(array, subset, msg = "")
    return UTF_PushErrorMessage(BTS__AssertArrayNotContainsSubset(array, subset, msg))
end function

function UTF_assertArrayCount(array, count, msg = "")
    return UTF_PushErrorMessage(BTS__AssertArrayCount(array, count, msg))
end function

function UTF_assertArrayNotCount(array, count, msg = "")
    return UTF_PushErrorMessage(BTS__AssertArrayNotCount(array, count, msg))
end function

function UTF_assertEmpty(item, msg = "")
    return UTF_PushErrorMessage(BTS__AssertEmpty(item, msg))
end function

function UTF_assertNotEmpty(item, msg = "")
    return UTF_PushErrorMessage(BTS__AssertNotEmpty(item, msg))
end function

function UTF_PushErrorMessage(message as string) as boolean
    result = Len(message) <= 0
    if not result then
        m.globalErrorsList.push(message)
    end if

    return result
end function'*****************************************************************
'* Copyright Roku 2011-2019
'* All Rights Reserved
'*****************************************************************
' Common framework utility functions
' *****************************************************************

' *************************************************
' TF_Utils__IsXmlElement - check if value contains XMLElement interface
' @param value As Dynamic
' @return As Boolean - true if value contains XMLElement interface, else return false
' *************************************************
function TF_Utils__IsXmlElement(value as dynamic) as boolean
    return TF_Utils__IsValid(value) and GetInterface(value, "ifXMLElement") <> invalid
end function

' *************************************************
' TF_Utils__IsFunction - check if value contains Function interface
' @param value As Dynamic
' @return As Boolean - true if value contains Function interface, else return false
' *************************************************
function TF_Utils__IsFunction(value as dynamic) as boolean
    return TF_Utils__IsValid(value) and GetInterface(value, "ifFunction") <> invalid
end function

' *************************************************
' TF_Utils__IsBoolean - check if value contains Boolean interface
' @param value As Dynamic
' @return As Boolean - true if value contains Boolean interface, else return false
' *************************************************
function TF_Utils__IsBoolean(value as dynamic) as boolean
    return TF_Utils__IsValid(value) and GetInterface(value, "ifBoolean") <> invalid
end function

' *************************************************
' TF_Utils__IsInteger - check if value type equals Integer
' @param value As Dynamic
' @return As Boolean - true if value type equals Integer, else return false
' *************************************************
function TF_Utils__IsInteger(value as dynamic) as boolean
    return TF_Utils__IsValid(value) and GetInterface(value, "ifInt") <> invalid and (Type(value) = "roInt" or Type(value) = "roInteger" or Type(value) = "Integer")
end function

' *************************************************
' TF_Utils__IsFloat - check if value contains Float interface
' @param value As Dynamic
' @return As Boolean - true if value contains Float interface, else return false
' *************************************************
function TF_Utils__IsFloat(value as dynamic) as boolean
    return TF_Utils__IsValid(value) and GetInterface(value, "ifFloat") <> invalid
end function

' *************************************************
' TF_Utils__IsDouble - check if value contains Double interface
' @param value As Dynamic
' @return As Boolean - true if value contains Double interface, else return false
' *************************************************
function TF_Utils__IsDouble(value as dynamic) as boolean
    return TF_Utils__IsValid(value) and GetInterface(value, "ifDouble") <> invalid
end function

' *************************************************
' TF_Utils__IsLongInteger - check if value contains LongInteger interface
' @param value As Dynamic
' @return As Boolean - true if value contains LongInteger interface, else return false
' *************************************************
function TF_Utils__IsLongInteger(value as dynamic) as boolean
    return TF_Utils__IsValid(value) and GetInterface(value, "ifLongInt") <> invalid
end function

' *************************************************
' TF_Utils__IsNumber - check if value contains LongInteger or Integer or Double or Float interface
' @param value As Dynamic
' @return As Boolean - true if value is number, else return false
' *************************************************
function TF_Utils__IsNumber(value as dynamic) as boolean
    return TF_Utils__IsLongInteger(value) or TF_Utils__IsDouble(value) or TF_Utils__IsInteger(value) or TF_Utils__IsFloat(value)
end function

' *************************************************
' TF_Utils__IsList - check if value contains List interface
' @param value As Dynamic
' @return As Boolean - true if value contains List interface, else return false
' *************************************************
function TF_Utils__IsList(value as dynamic) as boolean
    return TF_Utils__IsValid(value) and GetInterface(value, "ifList") <> invalid
end function

' *************************************************
' TF_Utils__IsArray - check if value contains Array interface
' @param value As Dynamic
' @return As Boolean - true if value contains Array interface, else return false
' *************************************************
function TF_Utils__IsArray(value as dynamic) as boolean
    return TF_Utils__IsValid(value) and GetInterface(value, "ifArray") <> invalid
end function

' *************************************************
' TF_Utils__IsAssociativeArray - check if value contains AssociativeArray interface
' @param value As Dynamic
' @return As Boolean - true if value contains AssociativeArray interface, else return false
' *************************************************
function TF_Utils__IsAssociativeArray(value as dynamic) as boolean
    return TF_Utils__IsValid(value) and GetInterface(value, "ifAssociativeArray") <> invalid
end function

' *************************************************
' TF_Utils__IsSGNode - check if value contains SGNodeChildren interface
' @param value As Dynamic
' @return As Boolean - true if value contains SGNodeChildren interface, else return false
' *************************************************
function TF_Utils__IsSGNode(value as dynamic) as boolean
    return TF_Utils__IsValid(value) and GetInterface(value, "ifSGNodeChildren") <> invalid
end function

' *************************************************
' TF_Utils__IsString - check if value contains String interface
' @param value As Dynamic
' @return As Boolean - true if value contains String interface, else return false
' *************************************************
function TF_Utils__IsString(value as dynamic) as boolean
    return TF_Utils__IsValid(value) and GetInterface(value, "ifString") <> invalid
end function

' *************************************************
' TF_Utils__IsNotEmptyString - check if value contains String interface and length more 0
' @param value As Dynamic
' @return As Boolean - true if value contains String interface and length more 0, else return false
' *************************************************
function TF_Utils__IsNotEmptyString(value as dynamic) as boolean
    return TF_Utils__IsString(value) and Len(value) > 0
end function

' *************************************************
' TF_Utils__IsDateTime - check if value contains DateTime interface
' @param value As Dynamic
' @return As Boolean - true if value contains DateTime interface, else return false
' *************************************************
function TF_Utils__IsDateTime(value as dynamic) as boolean
    return TF_Utils__IsValid(value) and (GetInterface(value, "ifDateTime") <> invalid or Type(value) = "roDateTime")
end function

' *************************************************
' TF_Utils__IsValid - check if value initialized and not equal invalid
' @param value As Dynamic
' @return As Boolean - true if value initialized and not equal invalid, else return false
' *************************************************
function TF_Utils__IsValid(value as dynamic) as boolean
    return Type(value) <> "<uninitialized>" and value <> invalid
end function

' *************************************************
' TF_Utils__ValidStr - return value if his contains String interface else return empty string
' @param value As Object
' @return As String - value if his contains String interface else return empty string
' *************************************************
function TF_Utils__ValidStr(obj as object) as string
    if obj <> invalid and GetInterface(obj, "ifString") <> invalid
        return obj
    else
        return ""
    end if
end function

' *************************************************
' TF_Utils__AsString - convert input to String if this possible, else return empty string
' @param input As Dynamic
' @return As String - return converted string
' *************************************************
function TF_Utils__AsString(input as dynamic) as string
    if TF_Utils__IsValid(input) = false
        return ""
    else if TF_Utils__IsString(input)
        return input
    else if TF_Utils__IsInteger(input) or TF_Utils__IsLongInteger(input) or TF_Utils__IsBoolean(input)
        return input.ToStr()
    else if TF_Utils__IsFloat(input) or TF_Utils__IsDouble(input)
        return Str(input).Trim()
    else
        return ""
    end if
end function

' *************************************************
' TF_Utils__AsInteger - convert input to Integer if this possible, else return 0
' @param input As Dynamic
' @return As Integer - return converted Integer
' *************************************************
function TF_Utils__AsInteger(input as dynamic) as integer
    if TF_Utils__IsValid(input) = false
        return 0
    else if TF_Utils__IsString(input)
        return input.ToInt()
    else if TF_Utils__IsInteger(input)
        return input
    else if TF_Utils__IsFloat(input) or TF_Utils__IsDouble(input) or TF_Utils__IsLongInteger(input)
        return Int(input)
    else
        return 0
    end if
end function

' *************************************************
' TF_Utils__AsLongInteger - convert input to LongInteger if this possible, else return 0
' @param input As Dynamic
' @return As Integer - return converted LongInteger
' *************************************************
function TF_Utils__AsLongInteger(input as dynamic) as longinteger
    if TF_Utils__IsValid(input) = false
        return 0
    else if TF_Utils__IsString(input)
        return TF_Utils__AsInteger(input)
    else if TF_Utils__IsLongInteger(input) or TF_Utils__IsFloat(input) or TF_Utils__IsDouble(input) or TF_Utils__IsInteger(input)
        return input
    else
        return 0
    end if
end function

' *************************************************
' TF_Utils__AsFloat - convert input to Float if this possible, else return 0.0
' @param input As Dynamic
' @return As Float - return converted Float
' *************************************************
function TF_Utils__AsFloat(input as dynamic) as float
    if TF_Utils__IsValid(input) = false
        return 0.0
    else if TF_Utils__IsString(input)
        return input.ToFloat()
    else if TF_Utils__IsInteger(input)
        return (input / 1)
    else if TF_Utils__IsFloat(input) or TF_Utils__IsDouble(input) or TF_Utils__IsLongInteger(input)
        return input
    else
        return 0.0
    end if
end function

' *************************************************
' TF_Utils__AsDouble - convert input to Double if this possible, else return 0.0
' @param input As Dynamic
' @return As Float - return converted Double
' *************************************************
function TF_Utils__AsDouble(input as dynamic) as double
    if TF_Utils__IsValid(input) = false
        return 0.0
    else if TF_Utils__IsString(input)
        return TF_Utils__AsFloat(input)
    else if TF_Utils__IsInteger(input) or TF_Utils__IsLongInteger(input) or TF_Utils__IsFloat(input) or TF_Utils__IsDouble(input)
        return input
    else
        return 0.0
    end if
end function

' *************************************************
' TF_Utils__AsBoolean - convert input to Boolean if this possible, else return False
' @param input As Dynamic
' @return As Boolean
' *************************************************
function TF_Utils__AsBoolean(input as dynamic) as boolean
    if TF_Utils__IsValid(input) = false
        return false
    else if TF_Utils__IsString(input)
        return LCase(input) = "true"
    else if TF_Utils__IsInteger(input) or TF_Utils__IsFloat(input)
        return input <> 0
    else if TF_Utils__IsBoolean(input)
        return input
    else
        return false
    end if
end function

' *************************************************
' TF_Utils__AsArray - if type of value equals array return value, else return array with one element [value]
' @param value As Object
' @return As Object - roArray
' *************************************************
function TF_Utils__AsArray(value as object) as object
    if TF_Utils__IsValid(value)
        if not TF_Utils__IsArray(value)
            return [value]
        else
            return value
        end if
    end if
    return []
end function

' =====================
' Strings
' =====================

' *************************************************
' TF_Utils__IsNullOrEmpty - check if value is invalid or empty
' @param value As Dynamic
' @return As Boolean - true if value is null or empty string, else return false
' *************************************************
function TF_Utils__IsNullOrEmpty(value as dynamic) as boolean
    if TF_Utils__IsString(value)
        return Len(value) = 0
    else
        return not TF_Utils__IsValid(value)
    end if
end function

' =====================
' Arrays
' =====================

' *************************************************
' TF_Utils__FindElementIndexInArray - find an element index in array
' @param array As Object
' @param value As Object
' @param compareAttribute As Dynamic
' @param caseSensitive As Boolean
' @return As Integer - element index if array contains a value, else return -1
' *************************************************
function TF_Utils__FindElementIndexInArray(array as object, value as object, compareAttribute = invalid as dynamic, caseSensitive = false as boolean) as integer
    if TF_Utils__IsArray(array)
        for i = 0 to TF_Utils__AsArray(array).Count() - 1
            compareValue = array[i]

            if compareAttribute <> invalid and TF_Utils__IsAssociativeArray(compareValue) and compareValue.DoesExist(compareAttribute)
                compareValue = compareValue.LookupCI(compareAttribute)
            end if

            if TF_Utils__IsString(compareValue) and TF_Utils__IsString(value) and not caseSensitive
                if LCase(compareValue) = LCase(value)
                    return i
                end if
            else if TF_Utils__BaseComparator(compareValue, value)
                return i
            end if

            item = array[i]
        next
    end if

    return -1
end function

' *************************************************
' TF_Utils__ArrayContains - check if array contains specified value
' @param array As Object
' @param value As Object
' @param compareAttribute As Dynamic
' @return As Boolean - true if array contains a value, else return false
' *************************************************
function TF_Utils__ArrayContains(array as object, value as object, compareAttribute = invalid as dynamic) as boolean
    return (TF_Utils__FindElementIndexInArray(array, value, compareAttribute) > -1)
end function

' ----------------------------------------------------------------
' Type Comparison Functionality
' ----------------------------------------------------------------

' ----------------------------------------------------------------
' Compare two arbitrary values to each other.

' @param Value1 (dynamic) A first item to compare.
' @param Value2 (dynamic) A second item to compare.
' @param comparator (Function, optional) Function, to compare 2 values. Should take in 2 parameters and return either true or false.

' @return True if values are equal or False in other case.
' ----------------------------------------------------------------
function TF_Utils__EqValues(Value1 as dynamic, Value2 as dynamic, comparator = invalid as object) as boolean
    if comparator = invalid
        return TF_Utils__BaseComparator(value1, value2)
    else
        return comparator(value1, value2)
    end if
end function

' ----------------------------------------------------------------
' Base comparator for comparing two values.

' @param Value1 (dynamic) A first item to compare.
' @param Value2 (dynamic) A second item to compare.

' @return True if values are equal or False in other case.
function TF_Utils__BaseComparator(value1 as dynamic, value2 as dynamic) as boolean
    value1Type = Type(value1)
    value2Type = Type(value2)

    if (value1Type = "roList" or value1Type = "roArray") and (value2Type = "roList" or value2Type = "roArray")
        return TF_Utils__EqArray(value1, value2)
    else if value1Type = "roAssociativeArray" and value2Type = "roAssociativeArray"
        return TF_Utils__EqAssocArray(value1, value2)
    else if Type(box(value1), 3) = Type(box(value2), 3)
        return value1 = value2
    else
        return false
    end if
end function

' ----------------------------------------------------------------
' Compare two roAssociativeArray objects for equality.

' @param Value1 (object) A first associative array.
' @param Value2 (object) A second associative array.

' @return True if arrays are equal or False in other case.
' ----------------------------------------------------------------
function TF_Utils__EqAssocArray(Value1 as object, Value2 as object) as boolean
    l1 = Value1.Count()
    l2 = Value2.Count()

    if not l1 = l2
        return false
    else
        for each k in Value1
            if not Value2.DoesExist(k)
                return false
            else
                v1 = Value1[k]
                v2 = Value2[k]
                if not TF_Utils__EqValues(v1, v2)
                    return false
                end if
            end if
        end for
        return true
    end if
end function

' ----------------------------------------------------------------
' Compare two roArray objects for equality.

' @param Value1 (object) A first array.
' @param Value2 (object) A second array.

' @return True if arrays are equal or False in other case.
' ----------------------------------------------------------------
function TF_Utils__EqArray(Value1 as object, Value2 as object) as boolean
    l1 = Value1.Count()
    l2 = Value2.Count()

    if not l1 = l2
        return false
    else
        for i = 0 to l1 - 1
            v1 = Value1[i]
            v2 = Value2[i]
            if not TF_Utils__EqValues(v1, v2) then
                return false
            end if
        end for
        return true
    end if
end function
