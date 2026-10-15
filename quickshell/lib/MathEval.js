.pragma library

// Small calculator for the launcher's search box. A real parser (recursive descent), not
// eval(), so typed text is never run as code.
//   operators  + - * / % ^ (power, right-associative), × ÷, parentheses, unary minus
//   numbers    1.5, 1,5 (comma decimal), 1e3
//   constants  pi, e, tau
//   functions  sqrt cbrt abs exp ln log (base 10) log2 sin cos tan asin acos atan
//              floor ceil round (angles in radians)

const FUNCTIONS = {
    sqrt: Math.sqrt, cbrt: Math.cbrt, abs: Math.abs, exp: Math.exp,
    ln: Math.log, log: Math.log10, log2: Math.log2,
    sin: Math.sin, cos: Math.cos, tan: Math.tan,
    asin: Math.asin, acos: Math.acos, atan: Math.atan,
    floor: Math.floor, ceil: Math.ceil, round: Math.round
};
const CONSTANTS = { pi: Math.PI, e: Math.E, tau: 2 * Math.PI };

function tokenize(src) {
    const tokens = [];
    const re = /\s*(?:(\d+(?:[.,]\d+)?(?:e[+-]?\d+)?|[.,]\d+)|([a-z]+)|([-+*/%^()×÷]))/iy;
    let pos = 0;
    while (pos < src.length) {
        re.lastIndex = pos;
        const m = re.exec(src);
        if (!m) {
            if (/^\s*$/.test(src.slice(pos)))
                break;
            return null; // unexpected character
        }
        if (m[1] !== undefined)
            tokens.push({ type: "num", value: Number(m[1].replace(",", ".")) });
        else if (m[2] !== undefined)
            tokens.push({ type: "id", value: m[2].toLowerCase() });
        else
            tokens.push({ type: "op", value: m[3] === "×" ? "*" : m[3] === "÷" ? "/" : m[3] });
        pos = re.lastIndex;
    }
    return tokens;
}

// Returns { value, isCalculation } or null if `src` isn't a valid expression.
// isCalculation is false for a bare number or constant, so typing "42" doesn't show a result.
function evaluate(src) {
    const tokens = tokenize(src);
    if (!tokens || tokens.length === 0)
        return null;
    let i = 0, calculation = false;
    const peek = () => tokens[i];
    const take = () => tokens[i++];
    const isOp = v => peek()?.type === "op" && peek().value === v;

    function expr() {
        let v = term();
        while (isOp("+") || isOp("-")) {
            calculation = true;
            v = take().value === "+" ? v + term() : v - term();
        }
        return v;
    }
    function term() {
        let v = power();
        while (isOp("*") || isOp("/") || isOp("%")) {
            calculation = true;
            const op = take().value, r = power();
            v = op === "*" ? v * r : op === "/" ? v / r : v % r;
        }
        return v;
    }
    function power() {
        const base = unary();
        if (isOp("^")) {
            calculation = true;
            take();
            return Math.pow(base, power());
        }
        return base;
    }
    function unary() {
        if (isOp("-")) {
            take();
            return -unary();
        }
        if (isOp("+")) {
            take();
            return unary();
        }
        return primary();
    }
    function primary() {
        const t = take();
        if (!t)
            throw new Error("end");
        if (t.type === "num")
            return t.value;
        if (t.type === "op" && t.value === "(") {
            const v = expr();
            if (!isOp(")"))
                throw new Error(")");
            take();
            return v;
        }
        if (t.type === "id") {
            if (t.value in FUNCTIONS) {
                if (!isOp("("))
                    throw new Error("(");
                take();
                const v = expr();
                if (!isOp(")"))
                    throw new Error(")");
                take();
                calculation = true;
                return FUNCTIONS[t.value](v);
            }
            if (t.value in CONSTANTS)
                return CONSTANTS[t.value];
        }
        throw new Error("unexpected");
    }

    try {
        const value = expr();
        if (i !== tokens.length || !isFinite(value))
            return null;
        return { value, isCalculation: calculation };
    } catch (e) {
        return null;
    }
}

// Up to 12 significant digits, without trailing zeros
function format(v) {
    if (Number.isInteger(v) && Math.abs(v) < 1e15)
        return String(v);
    return String(Number(v.toPrecision(12)));
}
