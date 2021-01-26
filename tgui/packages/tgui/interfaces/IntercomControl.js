import { map, sortBy } from 'common/collections';
import { flow } from 'common/fp';
import { pureComponentHooks } from 'common/react';
import { useBackend, useLocalState } from '../backend';
import { Box, Button, Dimmer, Flex, Icon, Table, Tabs } from '../components';
import { Window } from '../layouts';

export const IntercomControl = (props, context) => {
  const { data } = useBackend(context);
  return (
    <Window
      title="Intercom Controller"
      width={550}
      height={500}
      resizable>
      {data.authenticated === 1 && (
        <IntercomLoggedIn />
      )}
      {data.authenticated === 0 && (
        <IntercomLoggedOut />
      )}
    </Window>
  );
};

const IntercomLoggedOut = (props, context) => {
  const { act, data } = useBackend(context);
  const { emagged } = data;
  const text = emagged === 1 ? 'Open' : 'Log In';
  return (
    <Window.Content>
      <Button
        fluid
        color={emagged === 1 ? '' : 'good'}
        content={text}
        onClick={() => act('log-in')} />
    </Window.Content>
  );
};

const IntercomLoggedIn = (props, context) => {
  const { act, data } = useBackend(context);
  const { restoring } = data;
  const [
    tabIndex,
    setTabIndex,
  ] = useLocalState(context, 'tab-index', 1);
  return (
    <>
      <Tabs>
        <Tabs.Tab
          selected={tabIndex === 1}
          onClick={() => {
            setTabIndex(1);
            act('check-intercoms');
          }}>
          Intercom Control Panel
        </Tabs.Tab>
        <Tabs.Tab
          selected={tabIndex === 2}
          onClick={() => {
            setTabIndex(2);
            act('check-logs');
          }}>
          Log View Panel
        </Tabs.Tab>
      </Tabs>
      {restoring === 1 && (
        <Dimmer fontSize="32px">
          <Icon name="cog" spin />
          {' Resetting...'}
        </Dimmer>
      )}
      {tabIndex === 1 && (
        <>
          <ControlPanel />
          <Box fillPositionedParent top="53px">
            <Window.Content scrollable>
              <ApcControlScene />
            </Window.Content>
          </Box>
        </>
      )}
      {tabIndex === 2 && (
        <Box fillPositionedParent top="20px">
          <Window.Content scrollable>
            <LogPanel />
          </Window.Content>
        </Box>
      )}
    </>
  );
};

const ControlPanel = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    emagged,
    logging,
  } = data;
  const [
    sortByField,
    setSortByField,
  ] = useLocalState(context, 'sortByField', null);
  return (
    <Flex>
      <Flex.Item>
        <Box inline mr={2} color="label">
          Sort by:
        </Box>
        <Button.Checkbox
          checked={sortByField === 'name'}
          content="Name"
          onClick={() => setSortByField(sortByField !== 'name' && 'name')} />
      </Flex.Item>
      <Flex.Item grow={1} />
      <Flex.Item>
        {emagged === 1 && (
          <>
            <Button
              color={logging === 1 ? 'bad' : 'good'}
              content={logging === 1 ? 'Stop Logging' : 'Restore Logging'}
              onClick={() => act('toggle-logs')}
            />
            <Button
              content="Reset Console"
              onClick={() => act('restore-console')}
            />
          </>
        )}
        <Button
          color="bad"
          content="Log Out"
          onClick={() => act('log-out')}
        />
      </Flex.Item>
    </Flex>
  );
};

const ApcControlScene = (props, context) => {
  const { data, act } = useBackend(context);

  const [
    sortByField,
  ] = useLocalState(context, 'sortByField', null);

  const intercoms = flow([
    map((intercom, i) => ({
      ...intercom,
      // Generate a unique id
      id: intercom.name + i,
    })),
    sortByField === 'name' && sortBy(intercom => intercom.name),
  ])(data.intercoms);
  return (
    <Table>
      <Table.Row header>
        <Table.Cell>
          Name
        </Table.Cell>
      </Table.Row>
      {intercoms.map((intercom, i) => (
        <tr
          key={intercom.id}
          className="Table__row  candystripe">
          <td>
            <Button
              onClick={() => act('access-intercom', {
                ref: intercom.ref,
              })}>
              {intercom.name}
            </Button>
          </td>
        </tr>
      ))}
    </Table>
  );
};

const LogPanel = (props, context) => {
  const { data } = useBackend(context);

  const logs = flow([
    map((line, i) => ({
      ...line,
      // Generate a unique id
      id: line.entry + i,
    })),
    logs => logs.reverse(),
  ])(data.logs);
  return (
    <Box m={-0.5}>
      {logs.map(line => (
        <Box
          p={0.5}
          key={line.id}
          className="candystripe"
          bold>
          {line.entry}
        </Box>
      ))}
    </Box>
  );
};

const AreaStatusColorButton = props => {
  const { target, status, intercom, act } = props;
  const power = Boolean(status & 2);
  const mode = Boolean(status & 1);
  return (
    <Button
      icon={mode ? 'sync' : 'power-off'}
      color={power ? 'good' : 'bad'}
      onClick={() => act('toggle-minor', {
        type: target,
        value: statusChange(status),
        ref: intercom.ref,
      })}
    />
  );
};

const statusChange = status => {
  // mode flip power flip both flip
  // 0, 2, 3
  return status === 0 ? 2 : status === 2 ? 3 : 0;
};

AreaStatusColorButton.defaultHooks = pureComponentHooks;

