import { testing } from "@winglang/sdk";

async function main() {
  const sim = new testing.Simulator({ simfile: "target/hello.wsim" });
  await sim.start();

  console.log(JSON.stringify(sim.tree(), null, 2));

  await sim.stop();
}

void main();
