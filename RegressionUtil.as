namespace RegressionUtil {

// A class representing a point in 2D space
class Point
{
  double x, y;
  Point(double x, double y) { this.x = x; this.y = y; }
}

// A class representing a linear line in 2D space
class Line
{
  double m, b;
  Line(double m, double b) { this.m = m; this.b = b; }

  Line() {}

  float solve(float x) {
    return m * x + b;
  }
}

// Calculates the slope and y-intercept of a linear line
// that best fits a set of points. The line is calculated
// using the least squares method.
Line bestFitLine(const array<Point@>& points)
{
  int n = points.Length;

  // Calculate the mean values of x and y
  double x_mean = 0.0;
  double y_mean = 0.0;
  for (int i = 0; i < n; i++)
  {
    x_mean += points[i].x;
    y_mean += points[i].y;
  }
  x_mean /= n;
  y_mean /= n;

  // Calculate the slope (m) and y-intercept (b) of the line
  double m = 0.0;
  double b = 0.0;
  for (int i = 0; i < n; i++)
  {
    m += (points[i].x - x_mean) * (points[i].y - y_mean);
    b += (points[i].x - x_mean) * (points[i].x - x_mean);
  }
  m /= b;
  b = y_mean - m * x_mean;

  return Line(m, b);
}

// Solves for the best fit line for a given array of CpLogs.
// The line is calculated based on the last CpLog in each
// inner array's attribute cp_time.
Line solve(const array<array<CpLog>>& logs)
{
  array<Point@> points;

  // Extract the last CpLog in each inner array and store
  // its cp_time as the y-coordinate and the run_id as the
  // x-coordinate of a point
  for (int i = 0; i < logs.Length; i++)
  {
    const CpLog@ last_log = logs[i][logs[i].Length - 1];
    points.InsertLast(Point(last_log.run_id, last_log.cp_time));
  }

  return bestFitLine(points);
}

}
