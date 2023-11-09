import {BigNumber} from 'bignumber.js';

function reductionCoefficient(x: BigNumber[], gamma: BigNumber): BigNumber {
  let x_prod = new BigNumber(1.0);
  const N = BigNumber(x.length);

  for (const x_i of x) {
    x_prod = x_prod.times(x_i);
  }

  let K = x_prod
    .dividedBy(
      x
        .reduce((acc, val) => acc.plus(val), new BigNumber(0))
        .exponentiatedBy(N),
    )
    .times(N.exponentiatedBy(N));

  if (gamma.isGreaterThan(0)) {
    K = gamma
      .dividedBy(gamma.plus(new BigNumber(1).minus(K)))
      .exponentiatedBy(-1);
  }

  return K;
}

function absnewton(
  f: (x: BigNumber) => BigNumber,
  fprime: (x: BigNumber) => BigNumber,
  x0: BigNumber,
  handle_x: boolean = false,
  handle_D: boolean = false,
): BigNumber {
  let x = x0;
  let i = 0;

  while (true) {
    const x_prev = x;
    const _f = f(x);
    const _fprime = fprime(x);

    x = x.minus(_f.dividedBy(_fprime));

    if (handle_x) {
      if (x.isLessThan(0) || _fprime.isLessThan(0)) {
        x = x_prev.dividedBy(2);
      }
    } else if (handle_D) {
      if (x.isLessThan(0)) {
        x = x.negated().dividedBy(2);
      }
    }

    i += 1;

    if (i > 1000) {
      console.log(i, x.minus(x_prev).dividedBy(x_prev));
    }

    if (x.minus(x_prev).abs().isLessThan(x_prev.times(1e-12))) {
      return x;
    }
  }
}

function invTarget(
  A: BigNumber,
  gamma: BigNumber,
  x: BigNumber[],
  D: BigNumber,
): BigNumber {
  const N = x.length;

  let x_prod = new BigNumber(1);
  for (const x_i of x) {
    x_prod = x_prod.times(x_i);
  }

  const K0 = x_prod.dividedBy(D.dividedBy(N).exponentiatedBy(N));

  let K = K0;

  if (gamma.isGreaterThan(0)) {
    K = gamma
      .pow(2)
      .times(K0)
      .dividedBy(
        gamma.plus(new BigNumber(10).exponentiatedBy(18).minus(K0)).pow(2),
      );
  }

  K = K.times(A);

  const f = K.times(D.exponentiatedBy(N - 1))
    .times(x.reduce((acc, x) => x.plus(acc), BigNumber(0)))
    .plus(x_prod)
    .minus(
      K.times(D.exponentiatedBy(N)).plus(D.dividedBy(N).exponentiatedBy(N)),
    );

  return f;
}

function invTargetDecimal(
  A: BigNumber,
  gamma: BigNumber,
  x: BigNumber[],
  D: BigNumber,
): BigNumber {
  const N = x.length;

  let x_prod = new BigNumber(1);
  for (const x_i of x) {
    x_prod = x_prod.times(x_i);
  }

  let K0 = x_prod.dividedBy(D.dividedBy(N).exponentiatedBy(N));
  K0 = K0.times(new BigNumber(10).exponentiatedBy(18));

  let K = K0;

  if (gamma.isGreaterThan(0)) {
    K = gamma
      .pow(2)
      .times(K0)
      .dividedBy(gamma.plus(new BigNumber(10).exponentiatedBy(18)).minus(K0))
      .pow(2)
      .dividedBy(new BigNumber(10).exponentiatedBy(18));
  }

  K = K.times(A);

  const f = K.times(D.exponentiatedBy(N - 1))
    .times(x.reduce((acc, x) => x.plus(acc), BigNumber(0)))
    .plus(x_prod)
    .minus(
      K.times(D.exponentiatedBy(N)).plus(D.dividedBy(N).exponentiatedBy(N)),
    );

  return f;
}

function invdfdD(
  A: BigNumber,
  gamma: BigNumber,
  x: BigNumber[],
  D: BigNumber,
): BigNumber {
  const N = BigNumber(x.length);

  let x_prod = new BigNumber(1);
  for (const x_i of x) {
    x_prod = x_prod.times(x_i);
  }

  const K0 = x_prod.dividedBy(D.dividedBy(N).exponentiatedBy(N));
  const K0deriv = new BigNumber(-N).dividedBy(D).times(K0);

  let K = K0;
  let Kderiv = K0deriv;

  if (gamma.isGreaterThan(0)) {
    K = gamma
      .pow(2)
      .times(K0)
      .dividedBy(gamma.plus(new BigNumber(1).minus(K0)).pow(2));
    Kderiv = gamma
      .pow(2)
      .times(K0)
      .dividedBy(gamma.plus(new BigNumber(1).minus(K0)).pow(3))
      .plus(
        gamma.pow(2).dividedBy(gamma.plus(new BigNumber(1).minus(K0)).pow(2)),
      )
      .times(K0deriv);
  }

  K = K.times(A);
  Kderiv = Kderiv.times(A);

  return BigNumber.sum(x.reduce((acc, x) => x.plus(acc), BigNumber(0))).times(
    D.exponentiatedBy(N.minus(2))
      .times(Kderiv.times(D).plus(K.times(N.minus(1))))
      .minus(
        D.exponentiatedBy(N.minus(1)).times(Kderiv.times(D).plus(K.times(N))),
      )
      .minus(D.dividedBy(N).exponentiatedBy(N.minus(1))),
  );
}

function invdfdxi(
  A: BigNumber,
  gamma: BigNumber,
  x: BigNumber[],
  D: BigNumber,
  i: number,
): BigNumber {
  const N = x.length;

  let x_prod = new BigNumber(1);
  let x_prod_i = new BigNumber(1);

  for (let j = 0; j < x.length; j++) {
    const x_i = x[j];
    x_prod = x_prod.times(x_i);

    if (j !== i) {
      x_prod_i = x_prod_i.times(x_i);
    }
  }

  const K0 = x_prod.dividedBy(D.dividedBy(N).exponentiatedBy(N));
  const K0deriv = x_prod_i.dividedBy(D.dividedBy(N).exponentiatedBy(N));

  let K = K0;
  let Kderiv = K0deriv;

  if (gamma.isGreaterThan(0)) {
    K = gamma
      .pow(2)
      .times(K0)
      .dividedBy(gamma.plus(new BigNumber(1).minus(K0)).pow(2));
    Kderiv = gamma
      .pow(2)
      .times(K0)
      .dividedBy(gamma.plus(new BigNumber(1).minus(K0)).pow(3))
      .plus(
        gamma.pow(2).dividedBy(gamma.plus(new BigNumber(1).minus(K0)).pow(2)),
      )
      .times(K0deriv);
  }

  K = K.times(A);
  Kderiv = Kderiv.times(A);

  return D.exponentiatedBy(N - 1)
    .times(
      K.plus(x.reduce((acc, x) => acc.plus(x), BigNumber(0)).times(Kderiv)),
    )
    .plus(x_prod_i)
    .minus(D.exponentiatedBy(N).times(Kderiv));
}

function solve_x(
  A: BigNumber,
  gamma: BigNumber,
  x: BigNumber[],
  D: BigNumber,
  i: number,
): BigNumber {
  let prod_i = new BigNumber(1);

  for (let j = 0; j < x.length; j++) {
    if (j !== i) {
      prod_i = prod_i.times(x[j]);
    }
  }

  const f = (x_i: BigNumber) => {
    const xx = x.slice();
    xx[i] = x_i;
    return invTarget(A, gamma, xx, D);
  };

  const f_der = (x_i: BigNumber) => {
    const xx = x.slice();
    xx[i] = x_i;
    return invdfdxi(A, gamma, xx, D, i);
  };

  try {
    const result = absnewton(
      f,
      f_der,
      D.dividedBy(2).exponentiatedBy(x.length).dividedBy(prod_i),
    );
    return result;
  } catch (error) {
    console.log('x');
    throw error;
  }
}

function solve_D(A: BigNumber, gamma: BigNumber, x: BigNumber[]): BigNumber {
  const f = (D: BigNumber) => invTarget(A, gamma, x, D);
  const f_der = (D: BigNumber) => invdfdD(A, gamma, x, D);

  let D0 = new BigNumber(1);

  for (const _x of x) {
    D0 = D0.times(_x);
  }

  D0 = D0.exponentiatedBy(1 / x.length).times(x.length);

  try {
    return absnewton(f, f_der, D0);
  } catch (error) {
    console.log('D');
    throw error;
  }
}

class Curve {
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
    p: BigNumber[] | null = null,
  ) {
    this.A = A;
    this.gamma = gamma;
    this.n = n;
    this.p = p ? p : Array(n).fill(new BigNumber(10).exponentiatedBy(18));
    this.x = Array.from({length: n}, (_, i) =>
      D.dividedBy(n)
        .times(new BigNumber(10).exponentiatedBy(18))
        .dividedBy(this.p[i]),
    );
  }

  xp(): BigNumber[] {
    return this.x.map((value, i) =>
      value.times(this.p[i]).dividedBy(new BigNumber(10).exponentiatedBy(18)),
    );
  }

  D(): BigNumber {
    const xp = this.xp();

    if (xp.some((x) => x.isLessThanOrEqualTo(0))) {
      throw new Error('Invalid input');
    }

    return solve_D(this.A, this.gamma, xp);
  }

  cp_invariant(): BigNumber {
    let prod = new BigNumber(10).exponentiatedBy(18);

    for (const x of this.x) {
      prod = prod.times(x).dividedBy(new BigNumber(10).exponentiatedBy(18));
    }

    return prod;
  }

  y(x_i: BigNumber, i: number, j: number): BigNumber {
    const xp = this.xp();
    xp[i] = x_i
      .times(this.p[i])
      .dividedBy(new BigNumber(10).exponentiatedBy(18));
    const yp = solve_x(this.A, this.gamma, xp, this.D(), j);
    return yp.times(new BigNumber(10).exponentiatedBy(18)).dividedBy(this.p[j]);
  }

  get_p(): [number, number] {
    const ANN = this.A;
    const A = ANN.dividedBy(new BigNumber(10).exponentiatedBy(4))
      .dividedBy(3)
      .exponentiatedBy(3);
    const gamma = this.gamma.dividedBy(1e18);
    const xp = this.xp().map((_xp) => _xp.dividedBy(1e18));
    const D = this.D().dividedBy(1e18);

    const partial_derivatives = [
      get_partial_derivative(xp[1], xp[0], xp[2], D, gamma, A),
      get_partial_derivative(xp[2], xp[0], xp[1], D, gamma, A),
    ];

    return [
      Math.abs(partial_derivatives[0].times(this.p[1]).toNumber()),
      Math.abs(partial_derivatives[1].times(this.p[2]).toNumber()),
    ];
  }
}

function get_partial_derivative(
  x1: BigNumber,
  x2: BigNumber,
  x3: BigNumber,
  D: BigNumber,
  gamma: BigNumber,
  A: BigNumber,
): BigNumber {
  const a = new BigNumber(1)
    .plus(gamma)
    .times(
      new BigNumber(-1).plus(
        gamma.times(
          new BigNumber(-2).plus(
            new BigNumber(-1).plus(new BigNumber(27).times(A)).times(gamma),
          ),
        ),
      ),
    )
    .plus(
      new BigNumber(81).times(
        new BigNumber(1)
          .plus(
            gamma.times(
              new BigNumber(2)
                .plus(gamma)
                .plus(new BigNumber(9).times(A).times(gamma)),
            ),
          )
          .times(x1)
          .times(x2)
          .times(x3)
          .dividedBy(D.exponentiatedBy(3)),
      ),
    )
    .minus(
      new BigNumber(2187)
        .times(new BigNumber(1).plus(gamma))
        .times(x1.exponentiatedBy(2))
        .times(x2.exponentiatedBy(2))
        .times(x3.exponentiatedBy(2))
        .dividedBy(D.exponentiatedBy(6)),
    )
    .plus(
      new BigNumber(19683)
        .times(x1.exponentiatedBy(3))
        .times(x2.exponentiatedBy(3))
        .times(x3.exponentiatedBy(3))
        .dividedBy(D.exponentiatedBy(9)),
    );

  const b = new BigNumber(729)
    .times(A)
    .times(gamma.exponentiatedBy(2))
    .times(x1)
    .times(x2)
    .times(x3)
    .dividedBy(D.exponentiatedBy(4));
  const c = new BigNumber(27)
    .times(A)
    .times(gamma.exponentiatedBy(2))
    .times(new BigNumber(1).plus(gamma))
    .dividedBy(D);

  return x2
    .times(
      a.minus(
        b.times(x2.plus(x3)).minus(c.times(x1.times(2).plus(x2).plus(x3))),
      ),
    )
    .dividedBy(
      x1.times(
        a.minus(
          b.times(x1.plus(x3)).plus(c.times(x1.plus(x2.times(2)).plus(x3))),
        ),
      ),
    );
}
