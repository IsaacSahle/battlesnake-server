import {pipe} from './monad';

export function add(a: Point, b: Point): Point {
  return map2(a, b, (x, y) => x + y);
}

export function mul(a: Point, s: number): Point {
  return map(a, x => x * s);
}

export function div(a: Point, s: number): Point {
  return mul(a, 1 / s);
}

export function sub(a: Point, b: Point): Point {
  return add(a, mul(b, -1));
}

export function eq(a: Point, b: Point): boolean {
  return a[0] === b[0] && a[1] === b[1];
}

export function round(a: Point): Point {
  return map(a, Math.round);
}

export function uniq(s: Point[]): Point[] {
  return s
    .reduce(
      ([y, ...s], x) => {
        if (!eq(y, x)) {
          return [x, y, ...s];
        }
        return [y, ...s];
      },
      [s[0]]
    )
    .reverse();
}

// Add an interpolated point between every point in points.
export function smooth(points: Point[]): Point[] {
  return points.reduce((s: Point[], a: Point) => {
    if (s.length === 0) {
      return [a];
    }

    const [h, ...t] = s;
    const mean = div(add(a, h), 2);
    return [a, mean, h, ...t];
  }, []);
}

// Move the first and last points closer together.
export function shrink(points: Point[], scaler: number): Point[] {
  const [p0, p1] = points.slice(0, 2);
  const [s1, s0] = points.slice(-2);

  let pPrime = p0;
  let sPrime = s1;

  if (p1) {
    pPrime = pipe(p0)
      .map(p => sub(p, p1))
      .map(normalize)
      .map(p => mul(p, scaler))
      .map(p => add(p, p1)).value;
  }

  if (s0) {
    sPrime = pipe(s0)
      .map(p => sub(p, s1))
      .map(normalize)
      .map(p => mul(p, scaler))
      .map(p => add(p, s1)).value;
  }

  const result = [pPrime, p1, ...points.slice(1, -1), s1, sPrime];

  return result.filter(x => x);
}

export function map<T>(a: Point, fn: (x: number) => T): [T, T] {
  return [fn(a[0]), fn(a[1])];
}

export function map2<T>(
  a: Point,
  b: Point,
  fn: (x: number, y: number) => T
): [T, T] {
  return [fn(a[0], b[0]), fn(a[1], b[1])];
}

/**
 * Magnitude
 */
function mag([x, y]: Point): number {
  return Math.sqrt(x * x + y * y);
}

function normalize(a: Point): Point {
  const m = mag(a);
  return map(a, x => (m ? x / m : 0));
}
