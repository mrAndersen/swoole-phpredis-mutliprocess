<?php

declare(strict_types=1);

namespace App\Command;

use Exception;
use Psr\Log\LoggerInterface;
use RedisCluster;
use Swoole\Constant;
use Swoole\Http\Request;
use Swoole\Http\Response;
use Swoole\Http\Server;
use Swoole\Process;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Input\InputOption;
use Symfony\Component\Console\Output\OutputInterface;
use Throwable;
use const SWOOLE_DISPATCH_FDMOD;
use const SWOOLE_LOG_DEBUG;

class TestCommand extends Command
{
    public function __construct(
        protected readonly LoggerInterface $consoleLogger,
    )
    {
        parent::__construct();
    }

    /**
     * @var array<RedisCluster>
     */
    protected array $pool = [];

    public function getName(): ?string
    {
        return 'test:run';
    }

    /**
     * @throws Exception
     */
    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $dummy = new Server('0.0.0.0', 8080);

        $dummy->set([
            Constant::OPTION_LOG_LEVEL => SWOOLE_LOG_DEBUG,
            Constant::OPTION_SEND_YIELD => true,
            Constant::OPTION_HTTP_COMPRESSION => false,
            Constant::OPTION_DAEMONIZE => false,
            Constant::OPTION_ENABLE_COROUTINE => false,
            Constant::OPTION_DISPATCH_MODE => SWOOLE_DISPATCH_FDMOD,
            Constant::OPTION_WORKER_NUM => 1,
            Constant::OPTION_HOOK_FLAGS => 0,
            Constant::OPTION_ENABLE_STATIC_HANDLER => false,
        ]);

        $dummy->on(Constant::EVENT_REQUEST, function (Request $request, Response $response): void {
            $pid = getmypid();
            $redis = $this->pool[$pid] ?? null;

            if (!$redis) {
                $response->setStatusCode(400);
                $response->end();

                return;
            }

            $response->setStatusCode(200);
            $response->end($redis->get('hello'));
        });

        $dummy->on(Constant::EVENT_WORKER_START, function () {
            $pid = getmypid();
            $this->pool[$pid] = new RedisCluster(null, ["redis:6379", "redis1:6380", "redis2:6381"], 10, 10, true, "");
        });

        for ($i = 0; $i < 6; $i++) {
            if (!$dummy->addProcess(new Process(function (Process $process) use ($i): void {
                $i = 0;

                $pid = getmypid();
                $this->pool[$pid] = new RedisCluster(null, ["redis:6379", "redis1:6380", "redis2:6381"], 10, 10, true, "");

                echo(sprintf("Created Redis, pid=%d, spl_hash=%s\n", $pid, spl_object_hash($this->pool[$pid])));

                while (true) {
                    echo(sprintf("Hello from %d, i = %d\n", $pid, $i));

                    $this->pool[$pid]->set('hello', $i);
                    assert((int)$this->pool[$pid]->get('hello') === $i);

                    $i++;
                    sleep(2);
                }
            }))) {

            }
        }

        $dummy->start();
        return 0;
    }
}
