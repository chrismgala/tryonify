import { useEffect } from "react";
import { BrowserRouter } from "react-router-dom";
import { NavigationMenu, useAppBridge } from "@shopify/app-bridge-react";

import Routes from "./Routes";
import { useAppQuery } from "./hooks";
import initializeCrisp from "./lib/crisp";
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

  const { isLoading, error, data } = useAppQuery({
    url: "/api/v1/shop"
  });

  useEffect(() => {
    if (data?.shop) {
      initializeCrisp(data.shop);
    }
  }, [data]);

  return (
    <PolarisProvider>
      <BrowserRouter>
        <AppBridgeProvider>
          <QueryProvider>
            <I18nProvider>
              <NavigationMenu
                navigationLinks={[
                  {
                    label: 'Orders',
                    destination: '/',
                  },
                  {
                    label: 'Checkouts',
                    destination: '/checkouts',
                  },
                  {
                    label: 'Trial Plans',
                    destination: '/plans',
                  },
                  {
                    label: 'Settings',
                    destination: '/settings',
                  }
                ]}
                matcher={() => undefined}
              />
              <Routes pages={pages} />
            </I18nProvider>
          </QueryProvider>
        </AppBridgeProvider>
      </BrowserRouter>
    </PolarisProvider>
  );
}
