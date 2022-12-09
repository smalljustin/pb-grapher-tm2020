int DEFAULT = 1; 

float getAverage(array<float> values) {
    if (values.Length == 0) {
        return 0;
    }
    float sum = 0;
    float min = getMin(values);
    int count = 0;
    for (int i = 0; i < values.Length; i++) {
        if (values[i] < SLOW_RUN_CUTOFF * min) {
            sum += values[i];
            count += 1;
        }
    }
    return sum / count;
}

float getMin(array<float> values) {
    if (values.Length == 0) {
        return 0;
    }
    float min = values[0];
    for (int i = 1; i < values.Length; i++) {
        if (values[i] < min) {
            min = values[i];
        }
    }
    return min;
}

float __getStandardDeviation(array<float> values) {
    if (values.Length == 0) {
        // idk bro this will make rendering math easier
        return DEFAULT;
    }

    float avg = getAverage(values);
    float min = getMin(values);
    float rollingVariance = 0;
    int count = 0;

    for (int i = 0; i < values.Length; i++) {
        if (values[i] < SLOW_RUN_CUTOFF * min) {
            rollingVariance += (values[i] - avg) ** 2;
            count += 1;
        }
    }
    rollingVariance /= count;
    return rollingVariance ** 0.5;
}

float _getStandardDeviation(array<array<CpLog>> cpLogArrayArray) {
    if (cpLogArrayArray.Length == 0) {
        return DEFAULT;
    }

    array<float> runTimes();
    for (int i = 0; i < cpLogArrayArray.Length; i++) {
        runTimes.InsertLast(cpLogArrayArray[i][cpLogArrayArray[i].Length - 1].cp_time);
    }
    return __getStandardDeviation(runTimes);
}

float getStandardDeviation(array<array<CpLog>> cpLogArrayArray, int numLast) {
    // Gets the standard deviation of the last n elements.
    numLast = Math::Min(cpLogArrayArray.Length, numLast);

    array<array<CpLog>> sortedArr = insertionSort(cpLogArrayArray);

    array<array<CpLog>> runsForStandardDeviation(); 
    for (int i = 0; i < numLast; i++) {
        runsForStandardDeviation.InsertLast(sortedArr[i]);
    }
    return _getStandardDeviation(runsForStandardDeviation);
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

