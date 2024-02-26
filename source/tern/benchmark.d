module tern.benchmark;

import tern.meta;
import tern.traits;
import tern.algorithm;
import std.parallelism;
import std.datetime;
import std.stdio;
import std.conv;
import std.range;

public struct BenchmarkConfig
{
    uint warmup = 100;
    uint iterations = 1000;
    bool parallel = false;
}

public struct BenchmarkResult
{
    string functionName;
    size_t index;
    Duration duration;
    BenchmarkConfig config;
}

private:
static:
BenchmarkResult[] results;

public:
BenchmarkResult[] benchmark(FUNCS...)(BenchmarkConfig config)
    if (seqAll!(isCallable, FUNCS))
{
    BenchmarkResult[FUNCS.length] ret;
    if (!config.parallel)
    {
        foreach (i, F; FUNCS)
        {
            auto timestamp = Clock.currTime;
            writeln("[", timestamp.hour, ":", timestamp.minute, ":", timestamp.second, "] ", __traits(identifier, F), "() benchmarking...");
            
            foreach (j; 0..config.warmup)
                F();

            auto start = Clock.currTime;
            foreach (j; 0..config.iterations)
                F();

            auto duration = (Clock.currTime - start) / cast(float) config.iterations;
            ret[i] = BenchmarkResult(__traits(identifier, F)~"()", i, duration, config);
            results ~= BenchmarkResult(__traits(identifier, F)~"()", results.length, duration, config);

            timestamp = Clock.currTime;
            writeln("[", timestamp.hour, ":", timestamp.minute, ":", timestamp.second, "] ",  __traits(identifier, F), "() finished benchmark!");
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
                    writeln(\"[\", timestamp.hour, \":\", timestamp.minute, \":\", timestamp.second, \"] \", __traits(identifier, F), \"() benchmarking...\");
                    foreach (k; 0..config.warmup)
                        FUNCS["~j.to!string~"]();

                    auto start = Clock.currTime;
                    foreach (k; 0..config.iterations)
                        FUNCS["~j.to!string~"]();

                    auto duration = (Clock.currTime - start) / cast(float) config.iterations;
                    ret[i] = BenchmarkResult(__traits(identifier, F)~\"()\", i, duration, config);
                    results ~= BenchmarkResult(__traits(identifier, F)~\"()\", results.length, duration, config);

                    timestamp = Clock.currTime;
                    writeln(\"[\", timestamp.hour, \":\", timestamp.minute, \":\", timestamp.second, \"] \",  __traits(identifier, F), \"() finished benchmark!\");
                }");
        }
    }
    return ret.dup;
}

BenchmarkResult[] benchmark(alias F, ARGS...)(BenchmarkConfig config, ARGS args)
{
    auto timestamp = Clock.currTime;
    writeln("[", timestamp.hour, ":", timestamp.minute, ":", timestamp.second, "] ", __traits(identifier, F)~ARGS.stringof, " benchmarking...");

    foreach (i; 0..config.warmup)
        F(args);

    auto start = Clock.currTime;
    foreach (i; 0..config.iterations)
        F(args);

    auto duration = (Clock.currTime - start) / cast(float) config.iterations;
    auto result = BenchmarkResult(__traits(identifier, F)~ARGS.stringof, 0, duration, config);
    results ~= BenchmarkResult(__traits(identifier, F)~ARGS.stringof, results.length, duration, config);

    timestamp = Clock.currTime;
    writeln("[", timestamp.hour, ":", timestamp.minute, ":", timestamp.second, "] ",  __traits(identifier, F)~ARGS.stringof, " finished benchmark!");
    
    return [result];
}

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

void reportAll() 
{
    report(results);
}