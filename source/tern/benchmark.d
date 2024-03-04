/// Parameterizable benchmarking with support for parallel, global results, reports, etc.
module tern.benchmark;

import tern.traits;
import tern.meta;
import std.algorithm;
import std.parallelism;
import std.datetime;
import std.stdio;
import std.conv;
import std.range;

public struct BenchmarkConfig
{
public:
final:
    size_t warmup = 100;
    size_t iterations = 1000;
    bool parallel = false;
}

public struct BenchmarkResult
{
public:
final:
    string functionName;
    size_t index;
    Duration duration;
    BenchmarkConfig config;
}

private:
BenchmarkResult[] results;

public:
/**
 * Benchmarks all functions in `FUNCS` with the given config.
 *
 * Params:
 *  FUNCS = Sequence of functions to be benchmarked.
 *  config = Benchmark configuration.
 *
 * Remarks:
 *  May not be parameterized.
 */
BenchmarkResult[] benchmark(FUNCS...)(const scope BenchmarkConfig config)
    if (allSatisfy!(isCallable, FUNCS))
{
    BenchmarkResult[FUNCS.length] ret;
    if (!config.parallel)
    {
        foreach (i, F; FUNCS)
        {
            auto timestamp = Clock.currTime;
            writeln("[", timestamp.hour, ":", timestamp.minute, ":", timestamp.second, "] ", identifier!F, "() benchmarking...");
            
            foreach (j; 0..config.warmup)
                F();

            auto start = Clock.currTime;
            foreach (j; 0..config.iterations)
                F();

            auto duration = (Clock.currTime - start);
            ret[i] = BenchmarkResult(identifier!F~"()", i, duration, config);
            results ~= BenchmarkResult(identifier!F~"()", results.length, duration, config);

            timestamp = Clock.currTime;
            writeln("[", timestamp.hour, ":", timestamp.minute, ":", timestamp.second, "] ", identifier!F, "() finished benchmark!");
        }
    }
    else 
    {
        foreach (i; parallel(iota(0, FUNCS.length)))
        {
            static foreach (j, F; FUNCS)
                mixin("if (i == "~j.to!string~")
                {
                    auto timestamp = Clock.currTime;
                    writeln(\"[\", timestamp.hour, \":\", timestamp.minute, \":\", timestamp.second, \"] \", identifier!F, \"() benchmarking...\");
                    foreach (k; 0..config.warmup)
                        FUNCS["~j.to!string~"]();

                    auto start = Clock.currTime;
                    foreach (k; 0..config.iterations)
                        FUNCS["~j.to!string~"]();

                    auto duration = (Clock.currTime - start);
                    ret[i] = BenchmarkResult(identifier!F~\"()\", i, duration, config);
                    results ~= BenchmarkResult(identifier!F~\"()\", results.length, duration, config);

                    timestamp = Clock.currTime;
                    writeln(\"[\", timestamp.hour, \":\", timestamp.minute, \":\", timestamp.second, \"] \",  identifier!F, \"() finished benchmark!\");
                }");
        }
    }
    return ret.dup;
}

/**
 * Benchmarks `F` with the given config and arguments.
 *
 * Params:
 *  F = The function to be benchmarked.
 *  config = Benchmark configuration.
 *  args = The arguments to invoke `F` with.
 */
BenchmarkResult[] benchmark(alias F, ARGS...)(const scope BenchmarkConfig config, ARGS args)
{
    auto timestamp = Clock.currTime;
    writeln("[", timestamp.hour, ":", timestamp.minute, ":", timestamp.second, "] ", SignatureOf!F, " benchmarking...");

    foreach (i; 0..config.warmup)
        F(args);

    auto start = Clock.currTime;
    foreach (i; 0..config.iterations)
        F(args);

    auto duration = (Clock.currTime - start);
    auto result = BenchmarkResult(SignatureOf!F, 0, duration, config);
    results ~= BenchmarkResult(SignatureOf!F, results.length, duration, config);

    timestamp = Clock.currTime;
    writeln("[", timestamp.hour, ":", timestamp.minute, ":", timestamp.second, "] ",  SignatureOf!F, " finished benchmark!");
    
    return [result];
}

/**
 * Writes a report of `results` to the console.
 *
 * Params:
 *  results = The benchmark results to be written.
 */
void report(BenchmarkResult[] results) 
{
    writeln("BENCHMARK ["~__VENDOR__~" "~__VERSION__.to!string~"]");
    writeln("-----------------------------------------------------------------------------");
    writeln("| Index | Function                                 | Duration               |");
    writeln("-----------------------------------------------------------------------------");

    foreach (res; results)
    {
        auto duration = res.duration.split!("seconds", "msecs", "usecs");

        writef("| %-6s| %-40s | ", res.index, res.functionName);

        if (duration.seconds > 1)
            writefln("%-10.3fs            |", duration.seconds);
        else if (duration.msecs > 1)
            writefln("%-10.3fms           |", duration.msecs);
        else
            writefln("%-10.3fus           |", duration.usecs);
    }

    writeln("-----------------------------------------------------------------------------");
}

/// Writes a report of all benchmarks that have been run to the console.
void reportAll() 
{
    report(results);
}