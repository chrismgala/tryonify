import { BrowserRouter } from "react-router-dom";
import { NavigationMenu } from "@shopify/app-bridge-react";
import Routes from "./Routes";

import {
  AppBridgeProvider,
  QueryProvider,
  PolarisProvider,
  I18nProvider,
} from "./components";

export default function App() {
  // Any .tsx or .jsx files in /pages will become a route
  // See documentation for <Routes /> for more info
  const pages = import.meta.globEager("./pages/**/!(*.test.[jt]sx)*.([jt]sx)");

  return (
    <PolarisProvider>
      <BrowserRouter>
        <AppBridgeProvider>
          <QueryProvider>
            <I18nProvider>
              <NavigationMenu
                navigationLinks={[
                  {
                    label: "Orders",
                    destination: "/",
                  },
                  {
                    label: "Trial Plans",
                    destination: "/plans",
                  },
                  {
                    label: "Settings",
                    destination: "/settings",
                  }
                ]}
              />
              <Routes pages={pages} />
            </I18nProvider>
          </QueryProvider>
        </AppBridgeProvider>
      </BrowserRouter>
    </PolarisProvider>
  );
}
