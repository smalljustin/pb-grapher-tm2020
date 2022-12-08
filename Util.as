int DEFAULT = 1; 

float __getAverage(array<float> values) {
    if (values.Length == 0) {
        return 0;
    }
    float sum = 0;
    for (int i = 0; i < values.Length; i++) {
        sum += values[i];
    }
    return sum / values.Length;
}

float getAverage(array<array<CpLog>> cpLogArrayArray) {
    if (cpLogArrayArray.Length == 0) {
        return DEFAULT;
    }

    array<float> valueArray();
    for (int i = 0; i < cpLogArrayArray.Length; i++) {
        valueArray.InsertLast(cpLogArrayArray[i][cpLogArrayArray[i].Length - 1].cp_time);
    }
    return __getAverage(valueArray);
}

float ___getStandardDeviation(array<float> values) {
    if (values.Length == 0) {
        // idk bro this will make rendering math easier
        return DEFAULT;
    }

    float avg = __getAverage(values);
    float rollingVariance = 0;

    for (int i = 0; i < values.Length; i++) {
        rollingVariance += Math::Abs(values[i] - avg);
    }

    return rollingVariance ** 0.5;
}

float __getStandardDeviation(array<CpLog> cpLogArray) {
    if (cpLogArray.Length == 0) {
        return DEFAULT;
    }
    array<float> runTimes();
    for (int i = 0; i < cpLogArray.Length; i++) {
        runTimes.InsertLast(cpLogArray[i].cp_time);
    }
    return ___getStandardDeviation(runTimes);
}

float _getStandardDeviation(array<array<CpLog>> cpLogArrayArray) {
    if (cpLogArrayArray.Length == 0) {
        return DEFAULT;
    }

    array<CpLog> cpLogArray();
    for (int i = 0; i < cpLogArrayArray.Length; i++) {
        cpLogArray.InsertLast(cpLogArrayArray[i][cpLogArrayArray[i].Length - 1]);
    }
    return __getStandardDeviation(cpLogArray);
}

float getStandardDeviation(array<array<CpLog>> cpLogArrayArray, int numLast) {
    // Gets the standard deviation of the last n elements.
    numLast = Math::Min(cpLogArrayArray.Length, numLast);

    array<array<CpLog>> sortedArr = insertionSort(cpLogArrayArray);

    array<array<CpLog>> runsForStandardDeviation(); 
    for (int i = 0; i < numLast; i++) {
        runsForStandardDeviation.InsertLast(sortedArr[i]);
    }
    return _getStandardDeviation(sortedArr);
}

RegressionUtil::Line solveRegressionForRecentPointsWithinStandardDeviation(array<array<CpLog>> cpLogArrayArray, int numLast, float numStandardDeviation) {
    float standard_deviation = getStandardDeviation(cpLogArrayArray, numLast);
    float average = getAverage(cpLogArrayArray);

    array<array<CpLog>> sortedArr = insertionSort(cpLogArrayArray);
    array<array<CpLog>> sortedArrWithinStandardDeviation();

    int i = 0; 
    while (i < sortedArr.Length && sortedArrWithinStandardDeviation.Length < numLast) {
        float runTime = sortedArr[i][sortedArr[i].Length - 1].cp_time;
        if (Math::Abs(runTime - average) < standard_deviation * numStandardDeviation) {
            sortedArrWithinStandardDeviation.InsertLast(sortedArr[i]);
        }
        i += 1;
    }
    return RegressionUtil::solve(sortedArrWithinStandardDeviation);
    
}

array<array<CpLog>> insertionSort(array<array<CpLog>> cpLogArrayArray)
{
    // Create a new array to hold the sorted inner arrays
    array<array<CpLog>> sortedArr();

    // Loop through the input array and add each inner array to the sorted array in the correct position based on the first run_id value
    for (int i = 0; i < cpLogArrayArray.Length; i++)
    {
        array<CpLog> innerArray = cpLogArrayArray[i];

        // Find the index where the current inner array should be inserted in the sorted array
        int insertIndex = 0;
        for (int j = 0; j < sortedArr.Length; j++)
        {
            if (innerArray[0].run_id < sortedArr[j][0].run_id)
            {
                insertIndex = j + 1;
            }
        }

        // Insert the current inner array at the correct index in the sorted array
        sortedArr.InsertAt(insertIndex, innerArray);
    }

    return sortedArr;
}