using System;
using System.Diagnostics;

namespace Meowdoku.Core
{
    public class SolveTimer
    {
        private readonly Stopwatch _stopwatch = new Stopwatch();

        public bool IsRunning => _stopwatch.IsRunning;
        public TimeSpan Elapsed => _stopwatch.Elapsed;

        public void Start()
        {
            if (!_stopwatch.IsRunning)
                _stopwatch.Start();
        }

        public void Stop()
        {
            if (_stopwatch.IsRunning)
                _stopwatch.Stop();
        }

        public void Reset()
        {
            _stopwatch.Reset();
        }
    }
}
