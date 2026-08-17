using NUnit.Framework;
using Meowdoku.Core;

namespace Meowdoku.Tests
{
    public class SolveTimerTests
    {
        [Test]
        public void NewTimer_IsNotRunning()
        {
            var timer = new SolveTimer();

            Assert.IsFalse(timer.IsRunning);
        }

        [Test]
        public void Start_SetsIsRunningTrue()
        {
            var timer = new SolveTimer();

            timer.Start();

            Assert.IsTrue(timer.IsRunning);
        }

        [Test]
        public void Stop_SetsIsRunningFalse()
        {
            var timer = new SolveTimer();
            timer.Start();

            timer.Stop();

            Assert.IsFalse(timer.IsRunning);
        }

        [Test]
        public void Start_CalledTwice_DoesNotThrow()
        {
            var timer = new SolveTimer();
            timer.Start();

            Assert.DoesNotThrow(() => timer.Start());
            Assert.IsTrue(timer.IsRunning);
        }

        [Test]
        public void Reset_WhenNotRunning_ZeroesElapsed()
        {
            var timer = new SolveTimer();
            timer.Start();
            timer.Stop();

            timer.Reset();

            Assert.AreEqual(System.TimeSpan.Zero, timer.Elapsed);
        }
    }
}
