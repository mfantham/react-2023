import { render } from "@testing-library/react";
import { App } from "./App";

describe("App", () => {
  it("renders the heading", () => {
    const { container } = render(<App />);
    const heading = container.querySelector("h1");
    expect(heading?.textContent).toBe(
      "React TypeScript Parcel Starter Template"
    );
  });
});
