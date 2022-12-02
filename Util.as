
float apply_derivative(float target, float current, float start, float dx) {
float base = Math::Abs((start - target)) / (2 ** (4 + TRANSITION_BASE_FACTOR));

if (dx == 0) {
    if (current < target) {
        return base / (8);
    } else {
        return -base / (8);
    }
}
float mid_bound = (start + target) / 2;
float next = dx + base;
float prev = dx - base; 

  if (current < target) {
    if ((current + next) < mid_bound) {
      return next; 
    } else {
      return prev;
    }
  } else {
    if ((current + next) > mid_bound) {
      return prev;
    } else {
      return next;
    }
  }
}