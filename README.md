# Health Insurance Cost Simulator

This is a program for simulating costs of different health insurance plan. The
approach is to specify probabilities for various events that generate insurance
claims, and then to simulate payment of those claims by various insurance plans
to collect statistics on costs.

Currently there is not much structure to this program (ultimately it should be
arranged into a Ruby package of some sort), but since I'll probably just need
the program once or twice a year, this documentation will suffice for now and
hopefully will be improved in coming iterations.


## Just Tell Me How It Works

The file `run.rb` contains a sample run of the program, using the files
`geha.csv` and `statistics.yaml` as inputs for insurance plans and claim
likelihoods, respectively. Note that the claim likelihoods data is personal to
the user since it indicates likelihoods of certain injuries or health
conditions, so a sample of that file is not included. There is an example YAML
snippet for that file given below in this README.


## The Big Picture

The general order of operations is:

1. Specify one or more ClaimSimulator objects that specify the probabilities and
   expected costs of different health events and resulting claims.

2. Input relevant information on insurance plans into InsurancePlan objects.

3. Repeatedly generate sets of claims using the ClaimSimulators, apply them to
   each InsurancePlan, and collect statistics from the resulting payment
   records.

## Simulating Claims

The ClaimSimulator object represents an event that triggers zero or more
insurance claims. Each ClaimSimulator includes a name and a probability
distribution that specifies how many of the events occur within a year. It also
includes zero or more claim probabilities (added with
`ClaimSimulator#add_claim_prob`), each of which contains a category and three
probability distributions:

1. The conditional probability for how many of this claim arise out of the
   event.

2. The out-of-pocket cost of the claim.

3. The discount rate for the insurance company's negotiated cost (leave this at
   zero unless there's a particular reason for differentiating the out-of-pocket
   and negotiated cost).

### Distributions

The probabilities and costs are represented as probability distributions, which
are handled in the Distribution module. As inputs to the ClaimSimulator class,
they are represented as text strings that the Distribution module interprets to
return a Ruby `proc` that generates random numbers on the specified
distribution. For example, `poisson 3` produces a procedure block that generates
random non-negative integers drawn from a Poisson distribution with expected
value 3.

Several distributions are coded into the Distribution class. As a convenience,
providing just a number as a "distribution" yields a procedure block that always
returns that number.

### Example ClaimSimulator

For example, consider the possibility of breaking one's leg, which you might
estimate to occur once every two years. Should the event occur, you might expect
for sure one emergency room visit, zero to two specialist visits, and one or two
x-rays. That could be coded perhaps as follows:

```yaml
Leg Break:
    probability: poisson 0.5
    emergency_room_care:
        probability: 1
        oop: uniform 1000 2000
        discount: 0
    specialist_visit:
        probability: binomial 2 0.75
        oop: lognormal 300 50
        discount: 0
    imaging:
        probability: uniform 1 2
        oop: lognormal 200 50
        discount: 0
```

This YAML format will be accepted by the method in `parse_tables.rb`.

The categories must conform to names in ClaimCategories, to ensure consistency
in naming. This requirement may be relaxed in the future.

## Insurance Plans

An InsurancePlan comprises:

- A name

- A premium amount. This should be annual, and incorporate any benefits such as
  rewards or perks that, if converted to cash value, would reduce the net
  premium paid. (For example, if a plan is HSA-compatible, you might want to
  compute the value of the tax benefit of the HSA and subtract it from the
  premium.)

- The deductible and out-of-pocket maximum for the plan.

- One or more coverage records, each of which comprises:

  - A claim category, matching one in ClaimCategories

  - A boolean flag for whether this plan covers the amount

  - A coinsurance fraction or copay amount, if it's covered

The primary function of the InsurancePlan is to pay out claims. To do so, it
must maintain state about how much of the deductible has been used and whether
the out-of-pocket maximum has been reached. The `InsurancePlan#pay_year` method
handles this state and produces a set of Payment objects representing payments
made (either by the insurance company or out-of-pocket).

There is a utility method in `parse_tables.rb` for reading InsurancePlans out of
a CSV file, and the included sample `geha.csv` exemplifies the format.

## Putting It All Together

The YearSimulator class manages the ClaimSimulators and InsurancePlans. Its task
is to generate a set of claims for a year, apply each of the InsurancePlans to
it, and collect statistics about the payments. Executed multiple times, the
YearSimulator ends up with statistics of many runs of possible claims.

The general order of operations is:

1. Add ClaimSimulators to the YearSimulator.

2. Add InsurancePlans to the YearSimulator.

3. Define callbacks for collecting statistics.

4. Validate the YearSimulator. This confirms that the callbacks are defined and
   that all of the possible claim categories that the ClaimSimulators could
   produce have defined coverage in each InsurancePlan.

5. Run `simulate` on the YearSimulator multiple times.

6. Retrieve statistics from the YearSimulator to produce output.

## Todo

- Claims within a ClaimSimulator are all generated independently, but that might
  not be accurate (a broken arm could be seen as a specialist visit, or as an
  emergency room visit alternatively). Currently there is no way to account for
  this.

- A plan may incorporate multiple deductibles or out-of-pocket maximums for
  different items (e.g., a special deductible for medications). Currently it is
  assumed that there is a single deductible and maximum across all payments.

- Coinsurance and copays are assumed to be mutually exclusive and fixed, but
  some plans include both for a particular claim type, or include variable
  copays (e.g., an amount per day of inpatient hospital care).


