import { createTRPCRouter } from './create-context';
import { authRouter } from './routes/auth';
import { circlesRouter } from './routes/circles';
import { inviteRouter } from './routes/invite';
import { gratitudesRouter } from './routes/gratitudes';
import { userRouter } from './routes/user';
import { notificationsRouter } from './routes/notifications';

export const appRouter = createTRPCRouter({
  auth: authRouter,
  user: userRouter,
  circles: circlesRouter,
  invite: inviteRouter,
  gratitudes: gratitudesRouter,
  notifications: notificationsRouter,
});

export type AppRouter = typeof appRouter;
