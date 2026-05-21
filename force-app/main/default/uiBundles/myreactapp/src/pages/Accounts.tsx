import { useEffect, useState } from 'react';
import { executeGraphQL } from '@/api/graphqlClient';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { Skeleton } from '@/components/ui/skeleton';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';

interface AccountNode {
  Id: string;
  Name: { value: string };
  Website?: { value: string };
}

interface AccountData {
  uiapi: {
    query: {
      Account: {
        edges: Array<{
          node: AccountNode;
        }>;
      };
    };
  };
}

const ACCOUNT_QUERY = `query GetAccounts {
  uiapi {
    query {
      Account {
        edges {
          node {
            Id
            Name { value }
            Website { value }
          }
        }
      }
    }
  }
}`;

export default function Accounts() {
  const [accounts, setAccounts] = useState<AccountNode[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchAccounts = async () => {
      try {
        setLoading(true);
        setError(null);

        const data = await executeGraphQL<AccountData, undefined>(
          ACCOUNT_QUERY
        );
        const accountNodes = data.uiapi.query.Account.edges.map(
          edge => edge.node
        );
        setAccounts(accountNodes);
      } catch (err) {
        setError(
          err instanceof Error ? err.message : 'Failed to fetch accounts'
        );
        console.error('Error fetching accounts:', err);
      } finally {
        setLoading(false);
      }
    };

    fetchAccounts();
  }, []);

  if (loading) {
    return (
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <h1 className="text-3xl font-bold text-gray-900 mb-6">取引先一覧</h1>
        <div className="space-y-2">
          <Skeleton className="h-12 w-full" />
          <Skeleton className="h-12 w-full" />
          <Skeleton className="h-12 w-full" />
          <Skeleton className="h-12 w-full" />
          <Skeleton className="h-12 w-full" />
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <h1 className="text-3xl font-bold text-gray-900 mb-6">取引先一覧</h1>
        <Alert variant="destructive">
          <AlertTitle>エラー</AlertTitle>
          <AlertDescription>{error}</AlertDescription>
        </Alert>
      </div>
    );
  }

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
      <div className="mb-6">
        <h1 className="text-3xl font-bold text-gray-900">取引先一覧</h1>全
        {accounts.length}件の取引先が登録されています
      </div>
      {accounts.length === 0 ? (
        <Alert>
          <AlertTitle>取引先がありません</AlertTitle>
          <AlertDescription>
            現在、登録されている取引先はありません。
          </AlertDescription>
        </Alert>
      ) : (
        <div className="border rounded-lg overflow-hidden">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="font-semibold">ID</TableHead>
                <TableHead className="font-semibold">取引先名</TableHead>
                <TableHead className="font-semibold">ウェブサイト</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {accounts.map(account => (
                <TableRow key={account.Id}>
                  <TableCell className="font-mono text-sm">
                    {account.Id}
                  </TableCell>
                  <TableCell className="font-medium">
                    {account.Name.value}
                  </TableCell>
                  <TableCell>
                    {account.Website?.value ? (
                      <a
                        href={account.Website.value}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="text-blue-600 hover:underline"
                      >
                        {account.Website.value}
                      </a>
                    ) : (
                      '—'
                    )}
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      )}
    </div>
  );
}
