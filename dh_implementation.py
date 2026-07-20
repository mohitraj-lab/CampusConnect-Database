import sys

def is_primitive_root(g, p):
    """Verifies if g is a primitive root modulo p."""
    if g <= 1 or g >= p:
        return False
    required_set = {num for num in range(1, p)}
    actual_set = {pow(g, powers, p) for powers in range(1, p)}
    return required_set == actual_set

def run_dh(p, alpha, a, b, party1_name, party2_name):
    print("=" * 65)
    print(f"DIFFIE-HELLMAN KEY EXCHANGE ({party1_name} & {party2_name})")
    print(f"Public Parameters: p={p}, α={alpha} | Private Keys: a={a}, b={b}")
    print("=" * 65)

    # Constraint 1: Private keys must satisfy 1 < a, b < p - 1
    if not (1 < a < p - 1) or not (1 < b < p - 1):
        sys.exit(f"Error: Private keys a={a} and b={b} must satisfy 1 < key < {p - 1}.")

    # Constraint 2: α must be a primitive root modulo p
    if not is_primitive_root(alpha, p):
        sys.exit(f"Error: Base α={alpha} is NOT a primitive root modulo p={p}.")

    # Step 1: Compute public keys
    A = pow(alpha, a, p)  # Party 1's Public Key
    B = pow(alpha, b, p)  # Party 2's Public Key

    # Step 2: Compute shared secret independently
    K_party1 = pow(B, a, p)  # Party 1 computes K = B^a mod p
    K_party2 = pow(A, b, p)  # Party 2 computes K = A^b mod p

    # Display results
    print(f"Public Prime (p):                       {p}")
    print(f"Public Primitive Base (α):              {alpha}")
    print(f"{party1_name}'s Private Key (a):         {a}")
    print(f"{party2_name}'s Private Key (b):           {b}")
    print(f"{party1_name}'s Computed Public Key (A):   {A}")
    print(f"{party2_name}'s Computed Public Key (B):     {B}")
    print(f"{party1_name}'s Shared Secret (K):       {K_party1}")
    print(f"{party2_name}'s Shared Secret (K):         {K_party2}")
    print(f"Do Computed Shared Secrets Match?:      {K_party1 == K_party2}")

    assert K_party1 == K_party2, "Diffie-Hellman Shared Secret Mismatch!"
    print("STATUS: PASSED SUCCESSFUL\n")

if __name__ == "__main__":
    # Test Case (a): Worked Example (Aarav and Bhavna)
    run_dh(p=29, alpha=2, a=5, b=12, party1_name="Aarav", party2_name="Bhavna")

    # Test Case (b): Additional Values (Diya and Vikram)
    run_dh(p=23, alpha=5, a=6, b=15, party1_name="Diya", party2_name="Vikram")