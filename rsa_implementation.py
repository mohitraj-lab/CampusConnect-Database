import math
import sys

def is_prime(n):
    if n < 2:
        return False
    for i in range(2, int(math.isqrt(n)) + 1):
        if n % i == 0:
            return False
    return True

def modular_inverse(e, phi):
    """Computes unique private exponent d (0 <= d < phi) such that (d * e) % phi == 1."""
    def extended_gcd(a, b):
        if a == 0:
            return b, 0, 1
        gcd, x1, y1 = extended_gcd(b % a, a)
        x = y1 - (b // a) * x1
        y = x1
        return gcd, x, y

    gcd, x, _ = extended_gcd(e, phi)
    if gcd != 1:
        raise ValueError("e and φ(n) are not coprime; modular inverse does not exist.")
    return x % phi  # Guarantees unique smallest solution in range 0 <= d < phi

def run_rsa(p, q, e, m, sender_name, receiver_name):
    print("=" * 65)
    print(f"RSA KEY EXCHANGE & ENCRYPTION SIMULATION ({sender_name} -> {receiver_name})")
    print(f"Inputs: p={p}, q={q}, e={e}, m={m}")
    print("=" * 65)

    # Constraint 1: p and q must be distinct primes
    if not is_prime(p) or not is_prime(q):
        sys.exit(f"Error: Inputs p={p} and q={q} must both be prime numbers.")
    if p == q:
        sys.exit(f"Error: p and q must be distinct primes (p = q = {p} is invalid).")

    # Step 1: Calculate n and φ(n)
    n = p * q
    phi = (p - 1) * (q - 1)

    # Constraint 2: Plaintext message m must satisfy 0 <= m < n
    if not (0 <= m < n):
        sys.exit(f"Error: Message m={m} violates constraint 0 <= m < n (n={n}).")

    # Step 2: Validate public exponent e
    if not (1 < e < phi):
        sys.exit(f"Error: Exponent e={e} must satisfy 1 < e < φ(n)={phi}.")
    if math.gcd(e, phi) != 1:
        sys.exit(f"Error: Exponent e={e} is not coprime to φ(n)={phi}.")

    # Step 3: Compute private exponent d
    d = modular_inverse(e, phi)

    # Step 4: Encrypt numeric message c = m^e mod n
    c = pow(m, e, n)

    # Step 5: Decrypt message m = c^d mod n
    recovered_m = pow(c, d, n)

    # Display intermediate mathematical values
    print(f"Modulus (n = p * q):           {n}")
    print(f"Euler's Totient φ(n):          {phi}")
    print(f"Public Exponent (e):           {e}")
    print(f"Private Exponent (d):          {d}")
    print(f"Encrypted Ciphertext (c):      {c}")
    print(f"Decrypted Message (recovered): {recovered_m}")
    print(f"Did Decryption Work?:          {m == recovered_m}")

    assert m == recovered_m, "RSA Decryption Failed!"
    print("STATUS: PASSED SUCCESSFUL\n")

if __name__ == "__main__":
    # Test Case (a): Worked Example (Ananya sending login token to server)
    run_rsa(p=3, q=11, e=3, m=4, sender_name="Ananya Sharma", receiver_name="CampusConnect Server")

    # Test Case (b): Additional Primes and Message (Rohan Verma sending OTP)
    run_rsa(p=17, q=23, e=5, m=88, sender_name="Rohan Verma", receiver_name="CampusConnect Server")