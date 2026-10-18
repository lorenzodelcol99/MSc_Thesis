# DSGE Model Estimation via VAR IRF Matching: The Short and Long of It

MSc Applied Economics thesis, University of Padova, supervised by Prof. Efrem Castelnuovo.

De Graeve and Westermark (2025) and Baumeister (2025) argue that VARs should carry more lags than the four conventionally used for quarterly data, because longer lags reduce both the bias and the variance of the impulse responses. The thesis asks what that does to a DSGE model estimated from those VARs. I replicate Altig, Christiano, Eichenbaum and Lindé and re-estimate their model by impulse response matching at four, eight and twelve lags.

## Method and data

Impulse response matching is a minimum distance estimator: it picks the structural parameters that minimise the distance between the responses the model implies and those of an identified VAR, horizon by horizon out to twenty quarters, each weighted by the inverse of its sampling variance. The data are ten quarterly US macro and financial series from 1959 to 2001. Three shocks are identified, monetary policy by a recursive restriction and two technology shocks by long run restrictions, and only their responses enter the matching.

## What I find

The lag order changes the economics. The cost of varying capital utilisation shrinks to zero, and that parameter is what makes firm specific capital bind, so the implied duration of prices rises from a quarter and a half to over two years, the unrealistic stickiness the model was built to avoid. Precision does not suffer: the VAR bands are narrower at almost every horizon.

## How to run

Everything is in MATLAB, in `Scripts/`: VAR estimation at each lag order, bootstrapped response bands, the minimisation, the implied structural parameters, Monte Carlo inference on the price stickiness parameters and delta method standard errors. `Scripts_VAR_Alignment/` holds the alignment exercise, and the two `Output` folders hold the figures and tables, which are exported straight into the LaTeX source.

## Files

- `Scripts/`, `Scripts_VAR_Alignment/`, the code.
- `Data/`, the series used by the VAR.
- `Original_ACEL_Replication/`, the authors' replication package, which is not mine.
- `Thesis_Text/`, `Final PDF Text/`, `Thesis_Slides/`, the written thesis and the slides.
