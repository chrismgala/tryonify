import React, { useCallback, useEffect, useState } from 'react';
import {
  Button,
  InlineStack,
  Radio,
  Text,
  TextBlock,
  TextField,
  useData,
  useContainer,
  useExtensionApi,
  useSessionToken
} from '@shopify/admin-ui-extensions-react';

export default function Add() {
  const data = useData();
  const api = useExtensionApi();
  const { getSessionToken } = useSessionToken();
  const [trialPlans, setTrialPlans] = useState([]);
  const [selected, setSelected] = useState([]);

  const fetchPlans = useCallback(async () => {
    const token = await getSessionToken();
    const resp = await fetch(`https://web-qla9.onrender.com/api/v1/selling_plan_groups`, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      }
    });
  }, []);

  useEffect(() => {
    fetchPlans();
  }, []);

  return (
    <>
      <InlineStack>
        {trialPlans.map(trialPlan => {
          const { id, title } = trialPlan;

          return (
            <Radio
              key={id}
              label={title}
              onChange={(checked) => {
                const plans = checked
                  ? selected.concat(id)
                  : selected.filter((selectedId) => selectedId !== id);
                setSelected(plans);
              }}
            />
          )
        })}
      </InlineStack>
    </>
  )
}