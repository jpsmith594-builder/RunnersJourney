enum Season { summer, autumn, winter, spring }

/// Works out the season from a date and hemisphere.
/// Northern: Dec-Feb winter, Mar-May spring, Jun-Aug summer, Sep-Nov autumn.
/// Southern is the same calendar shifted by six months.
Season seasonFor(DateTime date, {required bool southern}) {
  final m = date.month;
  final Season north;
  if (m == 12 || m <= 2) {
    north = Season.winter;
  } else if (m <= 5) {
    north = Season.spring;
  } else if (m <= 8) {
    north = Season.summer;
  } else {
    north = Season.autumn;
  }
  if (!southern) return north;
  switch (north) {
    case Season.winter:
      return Season.summer;
    case Season.summer:
      return Season.winter;
    case Season.spring:
      return Season.autumn;
    case Season.autumn:
      return Season.spring;
  }
}
