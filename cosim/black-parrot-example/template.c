/* BEEBS matmult benchmark
   Copyright (C) 2014 Embecosm Limited and University of Bristol
   Contributor James Pallister <james.pallister@bristol.ac.uk>
   This file is part of the Bristol/Embecosm Embedded Benchmark Suite.
   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
   GNU General Public License for more details.
   You should have received a copy of the GNU General Public License
   along with this program. If not, see <http://www.gnu.org/licenses/>. */

/* Original code from: WCET Benchmarks,
       http://www.mrtc.mdh.se/projects/wcet/benchmarks.html
   Permission to license under GPL obtained by email from Björn Lisper
 */

/* $Id: matmult.c,v 1.2 2005/04/04 11:34:58 csg Exp $ */

/* matmult.c */
/* was mm.c! */


/*----------------------------------------------------------------------*
 * To make this program compile under our assumed embedded environment,
 * we had to make several changes:
 * - Declare all functions in ANSI style, not K&R.
 *   this includes adding return types in all cases!
 * - Declare function prototypes
 * - Disable all output
 * - Disable all UNIX-style includes
 *
 * This is a program that was developed from mm.c to matmult.c by
 * Thomas Lundqvist at Chalmers.
 *----------------------------------------------------------------------*/
#ifdef MATMULT_FLOAT
#include <math.h>
#endif /* MATMULT_FLOAT */

#include "support.h"
/* This scale factor will be changed to equalise the runtime of the
   benchmarks. */
#ifdef MATMULT_FLOAT
#define SCALE_FACTOR    (REPEAT_FACTOR >> 5)
#define UPPERLIMIT {upper_limit}
{float_matrix}
#define RANDOM_VALUE ((float) RandomInteger () / 10.0)
#define ZERO 0.0
#define MOD_SIZE 255

int
values_match (float v1, float v2)
{{
  if (v1 != v2)
    {{
      int exp;
      float diff;

      /* Ignore the least significant bit of the mantissa
       * to account for any loss of precision due to floating point
       * operations */
      frexpf(v1, &exp);
      diff = fabsf(v1 - v2);
      /* TODO: Fix for big endian */
      if (diff > (1 << exp)) {{
	return 0;
      }}
    }}

  return 1;
}}

#elif defined MATMULT_INT
#define SCALE_FACTOR    (REPEAT_FACTOR >> 6)
#define UPPERLIMIT {upper_limit}
#define RANDOM_VALUE (RandomInteger ())
#define ZERO 0
#define MOD_SIZE 8095
{int_matrix}

int
values_match (long v1, long v2)
{{
  return (v1 == v2);
}}

#else
#error "No SCALE_FACTOR defined"
#endif

/*
 * MATRIX MULTIPLICATION BENCHMARK PROGRAM:
 * This program multiplies 2 square matrices resulting in a 3rd
 * matrix. It tests a compiler's speed in handling multidimensional
 * arrays and simple arithmetic.
 */




int Seed;
matrix ResultArray;

{array_a}

{array_b}

void Multiply(matrix A, matrix B, matrix Res);
void InitSeed(void);
void Test(matrix A, matrix B, matrix Res);
void Initialize(matrix Array);
int RandomInteger(void);

int benchmark()
{{
   Test(ArrayA, ArrayB, ResultArray);

   return 0;
}}


/*
 * Initializes the seed used in the random number generator.
 */
void InitSeed(void)
{{
   Seed = 0;
}}

/*
 * Runs a multiplication test on an array.  Calculates and prints the
 * time it takes to multiply the matrices.
 */
void Test(matrix A, matrix B, matrix Res)
{{
   Multiply(A, B, Res);
}}

/*
 * Generates random integers between 0 and 8095
 */
int RandomInteger(void)
{{
   Seed = ((Seed * 133) + 81) % MOD_SIZE;
   return (Seed);
}}

/*
 * Multiplies arrays A and B and stores the result in ResultArray.
 */
{Multiply}

{initialise_benchmark}

int verify_benchmark(int unused)
{{
  int i, j;
#ifdef MATMULT_FLOAT
  matrix exp = {exp_float};
#endif
#ifdef MATMULT_INT
  matrix exp = {exp_int};
#endif

{verification}
}}

/* vim: set ts=3 sw=3 et: */
