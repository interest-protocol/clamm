import Bignumber, {BigNumber} from 'bignumber.js';

const TEN = BigNumber(10);

const A_MULTIPLIER = 1000;
const PRECISION = Bignumber(1000000000000000000);

export const reductionCoefficient = (
  x: readonly Bignumber[],
  gamma: Bignumber,
): Bignumber => {
  let N = Bignumber(x.length);
  let xProd = PRECISION;
  let K = PRECISION;
  const S = x.reduce((acc, x) => acc.plus(x), Bignumber(0));

  for (const item of x) {
    xProd = xProd.multipliedBy(item).dividedBy(PRECISION);
    K = K.multipliedBy(N).multipliedBy(item).dividedBy(S);
  }

  if (gamma.isPositive())
    return gamma
      .multipliedBy(PRECISION)
      .dividedBy(gamma.plus(PRECISION).minus(K));

  return K;
};

const geometricMean = (x: readonly Bignumber[]): Bignumber => {
  const len = x.length;
  const sortedX = x.slice().sort((a, b) => b.minus(a).toNumber());
  let D = sortedX[0];

  for (let i = 0; i < 256; i++) {
    let D_prev = D;
    let tmp = PRECISION;

    for (const x of sortedX) {
      tmp = tmp.multipliedBy(x).dividedBy(D);
    }

    D = D.multipliedBy(
      Bignumber(len).minus(1).multipliedBy(PRECISION).plus(tmp),
    ).dividedBy(Bignumber(len).multipliedBy(PRECISION));

    const diff = D.gt(D_prev) ? D.minus(D_prev) : D_prev.minus(D);
    if (diff.lte(1) || diff.multipliedBy(PRECISION).lt(D)) return D;
  }

  throw new Error('Failed to converge');
};

const getFee = (
  x: readonly Bignumber[],
  feeGamma: Bignumber,
  midFee: Bignumber,
  outFee: Bignumber,
): Bignumber => {
  const f = reductionCoefficient(x, feeGamma);
  return midFee
    .multipliedBy(f)
    .plus(outFee.multipliedBy(PRECISION.minus(f)))
    .dividedBy(PRECISION);
};

const invariant = (
  A: Bignumber,
  gamma: Bignumber,
  x: readonly Bignumber[],
  D0: Bignumber,
): Bignumber => {
  let D = D0;

  const S = x.reduce((acc, x) => acc.plus(x), Bignumber(0));
  const sortedX = x.slice().sort((a, b) => b.minus(a).toNumber());
  const N = Bignumber(x.length);

  for (let i = 0; i < 255; i++) {
    let D_prev = D;

    let k0 = PRECISION;

    for (const item of sortedX) {
      k0 = k0.multipliedBy(item).multipliedBy(N).dividedBy(D);
    }

    let _g1k0 = gamma.plus(PRECISION);

    if (_g1k0.gt(k0)) {
      _g1k0 = _g1k0.minus(k0).plus(1);
    } else {
      _g1k0 = k0.minus(_g1k0).plus(1);
    }

    let mul1 = PRECISION.multipliedBy(D)
      .dividedBy(gamma)
      .multipliedBy(_g1k0)
      .dividedBy(gamma)
      .multipliedBy(_g1k0)
      .multipliedBy(A_MULTIPLIER)
      .dividedBy(A);

    let mul2 = PRECISION.multipliedBy(2)
      .multipliedBy(N)
      .multipliedBy(k0)
      .dividedBy(_g1k0);

    let neg_fprime = S.plus(S)
      .multipliedBy(mul2)
      .dividedBy(PRECISION)
      .plus(
        mul1
          .multipliedBy(N)
          .dividedBy(k0.minus(mul2.multipliedBy(D)))
          .dividedBy(PRECISION),
      );

    if (neg_fprime.isNegative()) throw new Error('Negative neg_fprime');

    const D_plus = D.multipliedBy(neg_fprime.plus(S)).dividedBy(neg_fprime);
    let D_minus = D.multipliedBy(D).dividedBy(neg_fprime);

    if (PRECISION.gt(k0)) {
      D_minus = D_minus.plus(
        D.multipliedBy(mul1.dividedBy(neg_fprime))
          .dividedBy(PRECISION)
          .multipliedBy(PRECISION.minus(k0))
          .div(k0),
      );
    } else {
      D_minus = D_minus.minus(
        D.multipliedBy(mul1.dividedBy(neg_fprime))
          .dividedBy(PRECISION)
          .multipliedBy(k0.minus(PRECISION))
          .div(k0),
      );
    }

    if (D_plus.gt(D_minus)) {
      D = D_plus.minus(D_minus);
    } else {
      D = D_minus.minus(D_plus);
    }

    const diff = D_prev.gt(D) ? D_prev.minus(D) : D.minus(D_prev);

    console.log(diff.toString());

    if (
      diff
        .multipliedBy(BigNumber(10).pow(14))
        .lt(BigNumber.max(D, BigNumber(10).pow(16)))
    )
      return D;
  }

  throw new Error('Failed to converge');
};

const y = (
  A: Bignumber,
  gamma: Bignumber,
  x: readonly BigNumber[],
  D: BigNumber,
  i: number,
): Bignumber => {
  const N = Bignumber(x.length);

  let y = D.dividedToIntegerBy(N);
  let k0_i = PRECISION;
  let S_i = BigNumber(0);
  let x_sorted = x
    .slice()
    .filter((_, index) => index != i)
    .sort((a, b) => b.minus(a).toNumber());

  const convergence_limit = BigNumber.maximum(
    BigNumber.maximum(...x_sorted).dividedToIntegerBy(TEN.pow(14)),
    D.dividedToIntegerBy(TEN.pow(14)),
    BigNumber(100),
  );

  for (const item of x_sorted) {
    y = y.multipliedBy(D).dividedToIntegerBy(item.multipliedBy(N));
    S_i = S_i.plus(item);
  }

  for (const item of x_sorted.slice(0, -1)) {
    k0_i = k0_i.multipliedBy(item).multipliedBy(N).dividedToIntegerBy(D);
  }

  for (let i = 0; i < 255; i++) {
    let y_prev = y;

    let K0 = k0_i.multipliedBy(y).multipliedBy(N).dividedToIntegerBy(D);
    let S = S_i.plus(y);

    let _g1k0 = gamma.plus(PRECISION).minus(K0).abs();

    const mul1 = D.times(PRECISION)
      .dividedToIntegerBy(gamma)
      .times(_g1k0)
      .dividedBy(gamma)
      .times(_g1k0)
      .times(A_MULTIPLIER)
      .dividedToIntegerBy(A);

    const mul2 = PRECISION.plus(
      BigNumber(2).times(PRECISION).times(K0).dividedToIntegerBy(_g1k0),
    );

    const yfprime = PRECISION.times(y)
      .plus(S.times(mul2))
      .plus(mul1)
      .minus(D.times(mul2));
    const fprime = yfprime.dividedToIntegerBy(y);

    if (fprime.isLessThanOrEqualTo(0)) {
      throw new Error("f' <= 0");
    }

    if (
      y
        .minus(y_prev)
        .abs()
        .isLessThanOrEqualTo(
          BigNumber.maximum(
            convergence_limit,
            y.dividedToIntegerBy(TEN.pow(14)),
          ),
        )
    ) {
      return y;
    }
  }

  throw new Error('Failed to converge');
};

const getPartialDerivative = (
  x1: BigNumber,
  x2: BigNumber,
  x3: BigNumber,
  d: BigNumber,
  gamma: BigNumber,
  A: BigNumber,
): BigNumber => {
  const a = BigNumber(1)
    .plus(gamma)
    .times(
      BigNumber(-1).plus(
        gamma.times(
          BigNumber(-2).plus(
            BigNumber(-1).plus(BigNumber(27).times(A)).times(gamma),
          ),
        ),
      ),
    )
    .plus(
      BigNumber(81)
        .times(
          BigNumber(1).plus(
            gamma.times(
              BigNumber(2).plus(gamma).plus(BigNumber(9).times(A).times(gamma)),
            ),
          ),
        )
        .times(x1)
        .times(x2)
        .times(x3)
        .dividedBy(d.pow(3)),
    )
    .minus(
      BigNumber(2187)
        .times(BigNumber(1).plus(gamma))
        .times(x1.pow(2))
        .times(x2.pow(2))
        .times(x3.pow(2))
        .dividedBy(d.pow(6)),
    )
    .plus(
      BigNumber(19683)
        .times(x1.pow(3))
        .times(x2.pow(3))
        .times(x3.pow(3))
        .dividedBy(d.pow(9)),
    );

  const b = BigNumber(729)
    .times(A)
    .times(gamma.pow(2))
    .times(x1)
    .times(x2)
    .times(x3)
    .dividedBy(d.pow(4));
  const c = BigNumber(27)
    .times(A)
    .times(gamma.pow(2))
    .times(BigNumber(1).plus(gamma))
    .dividedBy(d);

  const numerator = x2.times(
    a
      .minus(b.times(x2.plus(x3)))
      .minus(c.times(BigNumber(2).times(x1).plus(x2).plus(x3))),
  );
  const denominator = x1.times(
    a
      .negated()
      .plus(b.times(x1.plus(x3)))
      .plus(c.times(x1.plus(BigNumber(2).times(x2).plus(x3)))),
  );

  return numerator.dividedBy(denominator);
};

const solveX = (
  A: BigNumber,
  gamma: BigNumber,
  x: readonly BigNumber[],
  D: BigNumber,
  i: number,
): BigNumber => {
  return y(A, gamma, x, D, i);
};

export const solveD = (
  A: BigNumber,
  gamma: BigNumber,
  x: readonly BigNumber[],
): BigNumber => {
  let D0 = BigNumber(x.length).times(geometricMean(x));
  return invariant(A, gamma, x, D0);
};

export class Curve {
  A: BigNumber;
  gamma: BigNumber;
  n: number;
  p: BigNumber[];
  x: BigNumber[];

  constructor(
    A: BigNumber,
    gamma: BigNumber,
    D: BigNumber,
    n: number,
    p?: BigNumber[],
  ) {
    this.A = A;
    this.gamma = gamma;
    this.n = n;
    if (p) {
      this.p = p;
    } else {
      this.p = Array(n).fill(new BigNumber(10 ** 18));
    }
    this.x = Array.from({length: n}, (_, i) =>
      D.dividedToIntegerBy(n)
        .times(10 ** 18)
        .dividedToIntegerBy(this.p[i]),
    );
  }

  xp(): BigNumber[] {
    return this.x.map((x, i) =>
      x.times(this.p[i]).dividedToIntegerBy(10 ** 18),
    );
  }

  D(): BigNumber {
    const xp = this.xp();
    if (xp.some((x) => x.isLessThanOrEqualTo(0))) {
      throw new Error('Invalid input: xp must be greater than 0.');
    }
    return solveD(this.A, this.gamma, xp);
  }

  y(x: BigNumber, i: number, j: number): BigNumber {
    const xp = this.xp();
    xp[i] = x.times(this.p[i]).dividedToIntegerBy(10 ** 18);
    const yp = solveX(this.A, this.gamma, xp, this.D(), j);
    return yp.times(10 ** 18).dividedToIntegerBy(this.p[j]);
  }

  get_p(): number[] {
    const ANN = this.A;
    const A = ANN.dividedBy(10 ** 4).dividedBy(3 ** 3);
    const gamma = this.gamma.dividedBy(1e18);
    const xp = this.xp().map((_xp) => _xp.dividedBy(1e18));
    const D = this.D().dividedBy(1e18);

    const partial_derivatives = [
      getPartialDerivative(xp[1], xp[0], xp[2], D, gamma, A),
      getPartialDerivative(xp[2], xp[0], xp[1], D, gamma, A),
    ];

    return [
      Math.abs(partial_derivatives[0].times(this.p[1]).toNumber()),
      Math.abs(partial_derivatives[1].times(this.p[2]).toNumber()),
    ];
  }
}
